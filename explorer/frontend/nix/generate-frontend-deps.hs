#! /usr/bin/env nix-shell
#! nix-shell shell.nix -i runhaskell
{-# LANGUAGE OverloadedStrings, LambdaCase #-}

import Prelude hiding (FilePath)
import Turtle hiding (find)
import Nix.Parser
import Nix.Expr
import Nix.Pretty (prettyNix)
import Text.PrettyPrint.ANSI.Leijen (hPutDoc)
import Data.Fix
import qualified Data.Text as T
import qualified Data.Map as M
import System.IO (withFile, IOMode(WriteMode))
import Filesystem.Path.CurrentOS (encodeString)
import Data.Maybe (maybeToList, catMaybes)
import qualified Control.Foldl as Fold
import Data.Foldable (find)

main :: IO ()
main = do
  testMode <- options "Regenerate frontend dependencies" optionsParser
  sh $ if testMode
    then test
    else regen

regen :: Shell ()
regen = do
  echo "Regenerating nix for frontend"
  bower2nix "bower.json" "nix/bower-generated.nix"
  node2nix "package.json" (Just "package-lock.json") "nix/node-packages.nix"

bower2nix :: FilePath -> FilePath -> Shell ()
bower2nix src out = cachedShell [src] out $ \out' ->
  procs "bower2nix" [tt src, tt out'] empty

node2nix :: FilePath -> Maybe FilePath -> FilePath -> Shell ()
node2nix src lock out = cachedShell (src:maybeToList lock) out $ \out' -> do
  let composition = "composition.nix"
      nodePackages = filename out
      nix = directory out
  composition' <- mktempfile "." (tt composition)
  procs "node2nix" (["-6", "--development", "--input", tt src
                    , "--composition", tt composition'
                    , "--output", tt nodePackages
                    ] ++ maybe [] (\l -> ["--lock", tt l]) lock) empty
  liftIO $ fixNix (addSrcParam . changeSrc . fixUglify) nodePackages out'
  liftIO $ fixNix (addSrcParam . passSrc) composition' (nix </> composition)
  rm nodePackages
  mv "node-env.nix" (nix </> "node-env.nix")

test :: Shell ()
test = do
  echo "Checking that auto-generated frontend dependencies nix is up to date."
  b <- needsChange ["bower.json"] "nix/bower-generated.nix"
  n <- needsChange ["package.json", "package-lock.json"] "nix/node-packages.nix"
  when b $ echo " - bower-generated.nix needs update"
  when n $ echo " - node-packages.nix needs update"
  when (b || n) $ die "Consult explorer/frontend/README.md to fix this"

optionsParser :: Parser Bool
optionsParser = switch "test" 't' "Test freshness but don't regenerate"

----------------------------------------------------------------------------

-- | Run a shell command only if the destination file is out of date
-- with respect to the source file.
cachedShell :: [FilePath] -> FilePath -> (FilePath -> Shell ()) -> Shell ()
cachedShell srcs dst action = needsChange srcs dst >>= \case
  True -> do
    printf ("Generating " % fp % "\n") dst
    tmp <- mktempfile "." (tt $ basename dst)
    action tmp
    whenM (testpath dst) $ rm dst
    input tmp & stampFile srcs & output dst
  False -> printf (fp % " is already up to date according to " % fp % "\n") dst (head srcs)

-- | A file needs a change if its hash doesn't match or it doesn't exist.
needsChange :: [FilePath] -> FilePath -> Shell Bool
needsChange srcs dst = do
  exists <- testfile dst
  if exists
    then do
      let stamps = flip fold Fold.list . limit (length srcs)
      line <- stamps $ input dst
      hash <- stamps $ hashFile srcs
      pure $ or [ l /= h | (l, h) <- zip line hash ]
    else pure True

-- | sha256sum output prepended with a nix line comment symbol
hashFile :: [FilePath] -> Shell Line
hashFile srcs = fmap ("# " <>) (inproc "sha256sum" (map tt srcs) empty)

-- | Adds a hash to the top of the file
stampFile :: [FilePath] -> Shell Line -> Shell Line
stampFile ref f = cat [hashFile ref, f]

----------------------------------------------------------------------------

-- | Parse a nix file, apply fixup function to AST, write out nix file.
fixNix :: (NExpr -> NExpr) -> FilePath -> FilePath -> IO ()
fixNix fixup src dst = do
  Success nix <- parseNixFile (encodeString src)
  let doc = prettyNix (fixup nix)
  withFile (encodeString dst) WriteMode $ \handle ->
    hPutDoc handle doc

----------------------------------------------------------------------------
-- Functions to modify nix expressions. These are quite complicated
-- compared to sed patterns, but I wanted to see how well hnix works
-- for transforming nix.

-- | Adds a src argument to the top level of the file.
addSrcParam :: NExpr -> NExpr
addSrcParam (Fix e) = Fix $ case e of
  NAbs (ParamSet (FixedParamSet params) x) body ->
    NAbs (ParamSet (FixedParamSet (M.insert "src" Nothing params)) x) body
  exp -> exp

-- | Replaces src = ./. with inherit src.
changeSrc :: NExpr -> NExpr
changeSrc (Fix e) = Fix $ case e of
  NSet bs -> NSet (map changeSrcBinding bs)
  exp     -> fmap changeSrc exp
  where
    changeSrcBinding :: Binding NExpr -> Binding NExpr
    changeSrcBinding (NamedVar [StaticKey "src"] (Fix (NLiteralPath "./.")))
      = Inherit Nothing [StaticKey "src"]
    changeSrcBinding other = fmap changeSrc other

-- | Adds src to list of arguments passed to node-packages.nix
passSrc :: NExpr -> NExpr
passSrc (Fix e) = Fix $ case e of
  NApp (Fix (NApp (Fix (NSym "import"))
             (Fix (NLiteralPath "./node-packages.nix"))))
    (Fix (NSet attrs)) ->
    NApp (Fix (NApp (Fix (NSym "import"))
             (Fix (NLiteralPath "./node-packages.nix"))))
    (Fix (NSet (Inherit Nothing [StaticKey "src"]:attrs)))
  exp -> fmap passSrc exp


-- | Replaces references to uglify-js version 3 with version 2.
-- The build process won't work with version 3.
-- For some reason it's not easy to make npm use version 2.
-- Workaround is to tweak the generated packages.
fixUglify :: NExpr -> NExpr
fixUglify e = maybe e (flip replaceUglify e) (find isNew . bindingNames $ e)
  where
    isOld = T.isPrefixOf "uglify-js-3"
    isNew = T.isPrefixOf "uglify-js-2"

    -- replace sources."uglify-js-3.xxx" with sources."uglify-js-2.xxx"
    replaceUglify :: Text -> NExpr -> NExpr
    replaceUglify new (Fix e) = Fix $ case e of
      NSelect (Fix (NSym "sources")) [DynamicKey (Plain (DoubleQuoted [Plain pkg]))] Nothing
        | isOld pkg
          -> NSelect (Fix (NSym "sources")) [DynamicKey (Plain (DoubleQuoted [Plain new]))] Nothing
      exp -> fmap (replaceUglify new) exp

-- big flat list of names of bindings { name = value; }
bindingNames :: NExpr -> [Text]
bindingNames = cata phi
  where
    phi (NSet bs) = names bs
    phi (NList xs) = concat xs
    phi (NAbs _ r) = r
    phi (NLet bs r) = names bs ++ r
    phi _ = []

    names bs = ns ++ concat vs
      where (ns, vs) = unzip . catMaybes . map nameValue $ bs

    -- gets the parts of a binding { name = value; }
    nameValue :: Binding r -> Maybe (Text, r)
    nameValue (NamedVar [v] r) = case v of
      StaticKey n -> Just (n, r)
      DynamicKey (Plain (DoubleQuoted [Plain n])) -> Just (n, r)
    nameValue (Inherit _ _) = Nothing

----------------------------------------------------------------------------

whenM :: Monad f => f Bool -> f () -> f ()
whenM f a = f >>= \t -> if t then a else pure ()

tt = format fp
