---
name: award-sweet-spots
description: Reference for legendary award redemptions where points dramatically outvalue cash. Catalogs sweet spots by tier (legendary/excellent/good) with current rates, devaluation history, and booking caveats. Load when making award recommendations, when a route or program matches a known sweet spot, or when a user asks "what are the best uses of my points?". Triggers on "sweet spot", "best uses of", "Iberia Avios to Madrid", "ANA First", "Hyatt all-inclusive", "Qatar Qsuites", "Virgin Atlantic to London", "outsized value", "Australia", "New Zealand", "Oceania", "South Pacific", "Tahiti", "Fiji", "Auckland", "Sydney", "Air New Zealand", "Qantas", "Fiji Airways", "Jetstar", "Kiritimati", "Bora Bora", or any redemption that might match a known high-value play.
category: reference
summary: Catalog of legendary, excellent, and good award redemptions with current rates and devaluation history.
---

# Award Sweet Spots

**Reference data:** `data/sweet-spots.json`

When making recommendations, cross-reference against known sweet spots. If a route matches a sweet spot, flag it prominently.

## Tier System

Sweet spots are ranked by tier:

- **Legendary:** Outsized value that travel hackers build entire trips around
  - Examples: ANA First via Virgin Atlantic, Hyatt All-Inclusive via World of Hyatt
- **Excellent:** Consistently great value, reliable availability
  - Examples: Iberia Avios to Madrid, Qatar Qsuites via various programs, Virgin Atlantic economy to London, Air New Zealand Business via Virgin Atlantic (62.5K), ANA Mileage Club Business to Oceania (65-72.5K)
- **Good:** Solid value but may have caveats like devaluations, limited availability, or surcharges
  - Examples: Air France LAX-Tahiti nonstop (30K economy), Aeroplan Business to Oceania (+5K Asia stopover), Atmos/Alaska to South Pacific islands

## Devaluations Matter

Always check the `devaluation_date` field in `data/sweet-spots.json`. If a sweet spot was recently devalued, mention the old vs new rates so users understand the change. A "legendary" tier sweet spot from 2023 may only be "good" or even "poor" today.

## How to Use This Reference

When a user's search returns options that match a known sweet spot:
1. Flag it prominently in the output. "This is the legendary Iberia Avios to Madrid sweet spot."
2. Show the current rate vs cash value.
3. Note any caveats (surcharges, booking-window restrictions, devaluations).
4. Compare against the next-best option to make the value concrete.

## Booking Windows

`data/sweet-spots.json` also has a `booking_windows` section. When a user asks about flights far in advance, check when award space opens for that airline. Some programs (Aeroplan) release space 358 days out. Others release 11 months. Knowing the window prevents wasted searches.

## Oceania / South Pacific Sweet Spots

Getting to Australia, New Zealand, and the South Pacific on points is hard — demand is high, distance is long, and premium cabin space is scarce. But there are proven plays:

### Top Picks (ranked)

1. **Air New Zealand Business via Virgin Atlantic** (Excellent) — 62.5K OW from US, 45K from Hawaii. Same flights United sells for 110K. Availability is the bottleneck: rare in advance, opens <30 days out. Phone booking only (1-800-365-9500). Reachable from: Amex, Bilt, Chase, Citi, Capital One (via Virgin Red), Wells Fargo.

2. **ANA Mileage Club Business to Oceania** (Excellent) — 65K OW on ANA metal (low season) or 72.5K on Star Alliance partners. Wide routing options: via Japan, Canada, or direct on Air NZ. No fuel surcharges on United/Air Canada/Air NZ. Limitation: only accessible via Amex MR (1:1) or Marriott (bad ratio).

3. **Aeroplan Business to Oceania** (Good) — 75-115K OW but the killer feature is the **Asia stopover for just +5K miles**. Turn Australia into Asia+Australia. No fuel surcharges (Aeroplan suppresses them). Lap infants just $25 CAD. Reachable from: Amex, Bilt, Capital One, Chase.

4. **Air France LAX-Tahiti Nonstop** (Good) — 30K economy OW on one of very few US-Tahiti nonstops. Business at ~113K is usually poor value. Economy is the play. Watch for transfer bonuses to Flying Blue. Reachable from all 6 currencies.

5. **Atmos/Alaska to South Pacific** (Good) — HNL-Kiritimati on Fiji Airways for 7.5K economy is almost always a steal. HNL-Tahiti/Rarotonga on Hawaiian for 25K economy. Free stopover, no change/cancel fees. Only reachable via Bilt (1:1).

6. **United MileagePlus Business** (Good) — 85-100K on UA metal, 110K on partners. Most lenient routing rules. Cardholders get 10-15% off. But partner flights are almost always cheaper via VA (62.5K) or ANA MC (72.5K).

### Key Warnings for Oceania Awards

- **Availability is the real constraint.** Points prices matter less if you can't find seats. Search early and often, especially for premium cabins.
- **Peak season is Dec-Feb** (Southern Hemisphere summer). Award space is hardest to find then.
- **Air NZ business via VA**: the best value but hardest to find. Only realistic <30 days out.
- **Don't connect on Delta to LAX** for Air France Tahiti flights — book a separate positioning flight. Delta segments inflate the Flying Blue price.
- **Surcharge traps**: BA Avios on Qantas metal = heavy surcharges. ANA MC on certain carriers = high surcharges. Stick to the "no surcharge" carriers listed in each entry.
