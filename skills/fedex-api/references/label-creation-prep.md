# FedEx label creation prep

This file documents the prep work for eventual label creation without enabling shipment purchase yet.

## Current state

The workspace now supports:

- FedEx OAuth
- rate/transit quote planning
- origin address config
- order-driven destination extraction
- weather-based shipment decisioning

## Before label creation

The following fields should be finalized and validated:

- shipper contact name
- shipper phone number
- recipient contact name
- recipient phone number
- package dimensions
- package weight
- packaging type
- service type selection
- label format preferences
- signature requirements
- live-animal handling constraints

Current workspace prep now includes:

- review-only label draft generation
- configurable package profile JSON
- review-only shipment payload generation for inspection before any live FedEx shipment call

## Safe next implementation step

Build a label-request payload generator that:

- is read-only by default
- writes a draft payload to disk
- does not purchase or confirm a shipment
- allows human review before any live label API call

## Non-goal

Do not create or buy labels automatically in the current phase.
