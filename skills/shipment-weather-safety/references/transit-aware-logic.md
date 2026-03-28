# Transit-aware logic

The shipping agent now combines weather policy with FedEx planning data.

## Current transit-aware rules

### Preferred carrier rule

If FedEx planning returns `PRIORITY_OVERNIGHT` as the preferred service, mark transit assessment as `acceptable`.

If not, mark as `review`.

### Weather override rule

If the shipment weather decision is already `HOLD`, transit planning does not override the hold.

### Planning unavailable rule

If FedEx planning is unavailable, transit assessment becomes `unavailable` and the operator summary notes the carrier planning failure.

## Current limitation

This is still a first-pass transit-aware layer. It does **not** yet use:

- exact delivery commitment timestamps
- explicit route/hub information
- corridor weather points
- packaging-specific assumptions

## Next transit-aware layer

Add support for:

- service-specific commitment details
- route or corridor checkpoints when available
- additional weather checks for likely transit nodes
- packaging and species sensitivity modifiers
- shipment payload validation feedback before label purchase
