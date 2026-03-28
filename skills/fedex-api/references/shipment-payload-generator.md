# Shipment payload generator

This stage prepares a review-only FedEx shipment payload from the latest eligible order.

## Inputs

- latest enriched shipping decision
- latest weather-ready shipment input
- package profile JSON
- FedEx origin config

## Output

A draft shipment payload that is formatted for eventual FedEx shipment/label creation, but is **not submitted**.

## Safety boundary

- `reviewOnly: true`
- no FedEx shipment creation calls are made
- no labels are purchased
- output is intended for inspection and refinement only
- readiness is reported separately from live execution

## Purpose

This lets the workflow mature toward label creation without crossing the line into live purchasing.
