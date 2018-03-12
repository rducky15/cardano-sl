# Technical Specification for Unified Backend Architecture

## Author Document Owner

Denis Shevchenko

## Document Owner

Denis Shevchenko

## Status

DRAFT

## Epic

[CHW-35](https://iohk.myjetbrains.com/youtrack/issue/CHW-35)

## Purpose

The purpose of this document is to describe Unified Backend Architecture.

We propose to unify the different use cases under a single architecture, starting from the crucial observation
that both interfacing with an hardware wallet or provide a mobile client can be seen as a specialisation of the
general case of having a “keyless” wallet backend operating with the private keys and cryptography “hosted”
elsewhere.

In the case of Ledger (or any external hardware wallet) the keys and the cryptography are hosted on the device,
whereas in a mobile client they are held on a smartphone. This schema fits even for “featherweight desktops”
that do not want to host the blockchain on the computer’s storage.

More specifically, a Daedalus mobile client will consist of an iOS or Android application which will communicate
with a cluster of nodes that will keep the global UTXO state for the blockchain and that will be capable
of reconstructing each mobile wallet state without hosting any user-specific data.

## Prerequisites

detail prerequisite knowledge of concepts, environment details, and so on, as appropriate here.

PENDING

## Assumptions

include details of assumptions that need to be called out in this section. This can be brief or detailed - it depends on the complexity and scope of the specification. Please ensure you do outline some assumptions.

PENDING

## Requirements

list the specific requirements for the specification here. Provide a link to the project charter. If none are defined, please specify (N/A with reason), rather than leaving this section blank (in the case of legacy specifications).

PENDING

## Use Case

Use Case/User Stories - detail the high level user stories that relate to the specification in this section. If none are defined, please specify (N/A with reason), rather than leaving this section blank (in the case of legacy specifications).

PENDING

## A description of the multi-tenant architecture, which shows the interaction between the various components;

PENDING

## A description of how the following operations will be implemented:

* Wallet creation
* Wallet import/export (via backup)
* Wallet restoration
* View balance
* Receive a payment
* Send a payment

## How a cluster of backend servers can scale to support the required number of users and how to ensure high availability for this service;

PENDING

## Authentication Scheme

### HTTPS

Client must be sure that server is not a malicious one, so we use standard check of TLS certs on the client side.

### Session

After successful TLS check client and server establish a new **session**.

PENDING

## API Work Flow

These are typical work flows, with description of API calls.

### Wallet Creation

1. Create a Wallet

PENDING

### Wallet Import/Export

PENDING

### Wallet Restoring

1. Restore Wallet

PENDING

### View Balance

1. Get Current Balance

PENDING

### Receive a Payment

1. Get Receive Address

PENDING

### Send a Payment

1. Create transaction.
2. Sign transaction.
3. Publish transaction.

PENDING

## An extension of the V1 wallet API covering both the mobile and the Ledger use cases (it can be delivered as a Swagger document);

PENDING

## A description of how the main operations on a crypto-wallet will be implemented, according to the final index derivation mechanism chosen (sequential vs random);

PENDING

## An analysis of the computational complexity of rebuilding the state of a wallet (e.g. balance & tx history) on the server in a way as much stateless as possible;

PENDING

## Security and Possible Attacks

A section covering the security aspects and the possible attacks (i.e. man-in-the-middle, MITM, attacks acting on
transaction fees) with their mitigation strategies, including an authentication schema to send and receive information
over the wire in a secure way.

### MITM

To prevent MITM attacks we have to change transaction's format for explicit including a fee in it.
