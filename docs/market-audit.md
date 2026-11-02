# Market and Competitor Audit: Golden Strategist EA

Date: 2026-11-02. Scope: retail MetaTrader 5 Expert Advisors (EAs) for gold (XAUUSD), the platforms and prop firms they run on, and the regulatory environment. Compares the market with the EA code in this repository (`Golden Strategist EA_v1.mq5`, `Golden Strategist EA_v2.mq5`, `ATRStopLoss_Ind.mq5`).

## 1. Summary

- **The market is large and crowded.** There are roughly 18,000 Expert Advisor listings on the MQL5 Market. Gold EAs sell for $190 to about $2,000, and the best-rated ones sell on verified live track records, reviews and "no grid / no martingale / prop-firm ready" claims.
- **Trust is the product.** Regulators say legitimate systems show verifiable live results, disclose their drawdowns and don't promise returns. Backtest-only curves are the main warning sign.
- **This EA is not sellable today.** It has no live track record, no backtest report in the repository, and no risk controls beyond a stop loss. v1 was effectively inactive until the session-filter bug was fixed in this branch (see `f503f5f`), and the code has not been compiled.
- **There is a credible niche.** Open, auditable code with built-in prop-firm rule compliance (no grid or martingale, news and spread filters, daily-loss limit, risk-based sizing) and a published, reproducible forward record. Most paid gold EAs are closed-source and sell on screenshots; prop-firm rules are the main reason traders get accounts closed.
- **Recommended position:** a free, transparent, prop-firm-ready core, with paid premium presets and a verified live signal. Outcompete on verifiability and compliance, not on claimed returns. We cannot promise profits. The gates in section 7 decide whether to sell at all.

## 2. Market

**Size.** Market-research firms put the algorithmic trading market at about $21.8 billion in 2025 ([2](https://dataintelo.com/report/algorithmic-trading-system-market)) to $24.06 billion ([1](https://www.theinsightpartners.com/reports/algorithm-trading-market)), growing 10 to 13% a year. These figures cover institutional software too, so they don't size the retail EA segment. Retail EA sales aren't reported in public sources.

**Platform share.** MT5 took 62% of retail CFD trading volume on MetaQuotes platforms in Q3 2025, and 15.7% of retail CFD volume ran on platforms other than MT4 or MT5 ([3](https://www.tradingview.com/news/financemagnates:9ea4aa5f4094b:0-mt5-extends-its-lead-over-mt4-as-platform-shift-accelerates/)). Note the denominator: the 62% is within MetaQuotes platforms. Affiliate blogs claim "over 65%" of retail forex share for MT5 without a source, so treat those figures with caution.

**Prop firms.** MT5 is offered by 23 of 53 firms (43%), Match Trader by 16, cTrader by 14 and TradingView by 12 ([4](https://propfirmmap.com/blog/prop-firm-platforms-mt5-ctrader-match-trader-compared-2026)). MT5 is still the default platform for EA-friendly prop firms.

**MQL5 Market.** The Expert Advisor category has roughly 18,000 listings (2,986 pages at 6 per page on the listing page) ([5](https://www.mql5.com/en/market/mt5/expert)). Sellers keep 80%. The commission is 20% with a $30 minimum price, and monthly rentals are available ([6](https://www.metatrader5.com/en/terminal/help/market/market_sell)). Purchases are bound to one computer and OS and can't be refunded. The Market does not guarantee profitability ([7](https://www.mql5.com/en/market/rules)).

**Price points, from the live listing page** ([5](https://www.mql5.com/en/market/mt5/expert)):

| Product (gold) | Price (USD) | Rating (reviews) | Notable claim |
|---|---|---|---|
| My AI Gold | 899.95 | 5 (16) | AI / neural network |
| The Invincible | 399.95 | not shown | No martingale, no grid, no hedging |
| The Gold Reaper MT5 | 949 | 4.4 (114) | Prop-firm ready, setfile, live signal |
| Quantum Titan MT5 | 1,299.99 | 4.76 (49) | Capped at 1,000 licences |

Other gold EAs named by third-party sites: Quantum Queen (self-described as the highest-rated seller; one blog reports 4.98 from over 400 reviews), Mad Turtle, EA Gold Stuff, XenClarity and Lizard ([8](https://newyorkcityservers.com/blog/best-mt5-expert-advisors)). Figures from these affiliate blogs are unverified; check each product page before using them.

**Free competitors.** The MQL5 Market's wall highlights "Gold Session Portfolio", a free five-strategy session EA with stop losses and no grid or martingale ([9](https://www.mql5.com/en/wall)). "GOLD SNIPING", one of the most downloaded free products, uses a grid with basket closing ([9](https://www.mql5.com/en/wall)). Free EAs that are transparent and have no grid are rare.

**Adjacent platforms.**
- TradingView: alerts and Pine Script, with webhook plans from $12.95 to $199.95 a month. Live execution requires a bridge such as PineConnector ($30 a month) ([10](https://www.quantvps.com/blog/best-automated-trading-platform), [11](https://techiefied.com/tradingview-vs-metatrader/)).
- cTrader: cBots in C#, with depth of market and free cloud instances through some brokers ([10](https://www.quantvps.com/blog/best-automated-trading-platform), [12](https://brokersroom.trade/platform-reviews)).
- Copy-trading and social "signal" sellers: the FCA warns about unauthorised "investment experts" offering signals on social media ([13](https://www.fastbull.com/brokersview/news/fca-warning-investment-experts-on-social-media-are-not-authorized-by-the-regulator-304895)).

## 3. Regulation and prop-firm rules

These rules decide which EAs can be sold and which accounts survive.

- **Regulators.** The CFTC and NFA have warned for years about automated-trading fraud and doctored backtests. Regulators say legitimate systems let you see the logic, show verified live results, disclose drawdowns and never guarantee returns ([14](https://www.aboutforexmarkets.com/forex-machine-trading.php)). Some robots require a specific broker, which is a common scam pattern ([15](https://www.topbrokers360.com/featured/forex-scam-warning-signs-fake-broker-checklist-2026/)).
- **Prop firms.** Most EA-friendly firms allow EAs in evaluation. Rules that close accounts include:
  - Hyperactivity: more than 2,000 server requests a day on FTMO ([16](https://www.nordman-algorithms.com/prop-firm-ea-rules-automated-trading-banned/)).
  - Grid and martingale: a comparison of prop firms lists martingale as banned at FTMO, The5ers, FXIFY, FundingPips and FundedNext ([17](https://fundedtrading.com/prop-firms-for-expert-advisors-ea-trading/)). Other sources say FTMO allows both but reviews them when drawdown limits are hit ([18](https://www.eafunded.com/firms/ftmo)). The sources conflict, so check FTMO's current terms.
  - News: a two-minute window around high-impact releases on some funded accounts ([16](https://www.nordman-algorithms.com/prop-firm-ea-rules-automated-trading-banned/)).
  - Capital allocation: FTMO caps a third-party strategy at $400,000 across all accounts ([16](https://www.nordman-algorithms.com/prop-firm-ea-rules-automated-trading-banned/)).
  - Rules change often. Check each firm's current terms before relying on any of these numbers.
- **Botswana.** This audit did not cover Botswana's rules for selling trading software or for promoting trading to local customers. Check with a licensed adviser before any commercial sale.

## 4. Gap analysis: Golden Strategist vs. market expectations

Rating: Critical = blocks selling, High = a buyer or prop trader will reject it, Medium = competitive disadvantage, Low = polish.

| Area | What the market expects | Golden Strategist (v1 / v2) | Gap |
|---|---|---|---|
| Verified live record | Live signal, 6+ months, real account | None | **Critical** |
| Backtest evidence | Every-tick, 5+ years, reported drawdown and profit factor | None in repo; never run | **Critical** |
| Compilation | Compiles on current MetaEditor | Not compiled here; v1 had a syntax error (fixed) | **Critical** |
| Magic number | Each EA identifies its own orders | None set. Orders use magic 0, shared with manual trades | **Critical** |
| Position management scope | Only manages its own positions | Trailing loop modifies every position on the symbol, including manual trades and other EAs | **Critical** |
| Risk-based sizing | Lot size set by % of equity, scaled to account | Fixed lot (v1 input, v2 hardcoded 0.02) | High |
| Daily loss and drawdown guard | Stops trading after a set loss (prop rules: 5% daily, 10% overall) | None | High |
| News filter | Blocks new trades around high-impact releases | None | High |
| Spread filter | Blocks entries when spread is too wide | None | High |
| Max trades per day / open trades | Caps exposure | One order cycle at a time; no daily cap | Medium |
| Take profit / exit logic | Several exit options, break-even | Stop loss only; trailing by indicator; no TP | Medium |
| Session and clock | Explicit server-time or GMT setting with conversion | Hour constants compared with server time; comments say GMT | Medium |
| Presets (setfiles) | Ready-made settings per account size or prop firm | None | Medium |
| Logging and monitoring | Panel, live monitoring, readable logs | Verbose `Print` only | Low |
| Documentation | Install guide, FAQ, risk disclosure | Rewritten README (this branch) | Low (now partly done) |
| Licence | Clear licence for buyers and users | No `LICENSE` file; README mentions MIT | High (blocks open-source positioning) |
| Distribution | MQL5 Market, prop-firm partnerships, signal | None | Medium |

Two findings are new from this audit, beyond the earlier bug fixes. The first is the magic-number and scope problem: the EA can modify manual trades on the same symbol, which is a serious issue for any account where it runs alongside other trading. The second is the lack of risk-based sizing: a fixed 0.02 lot on a small account carries a very different risk from the same lot on a large one.

## 5. Competitive positioning

Options:

1. **Another premium gold EA ($300 to $2,000).** Not recommended. The segment is saturated, the claims can't be checked, and our current code can't compete on track record.
2. **Open, prop-firm-ready gold EA (free core, paid premium presets and signal).** Recommended. It uses the audit's most concrete gaps: transparency, rule compliance and a verifiable record. It also fits the README's original goal of a beginner-friendly guide.
3. **Open-source education project only.** Low risk and good for goodwill, with little revenue. It can serve as the funnel for option 2.

Option 2 wins on:

- **Verifiability:** published backtests and forward results, with the same settings as the code, every period reported, failures included.
- **Compliance by design:** no grid, no martingale, no averaging, news and spread filters, daily-loss kill switch, max trades per day, hard stop loss on every order. This is the clearest opening against prop-firm closures.
- **Transparency:** readable source, documented logic, a licence buyers can rely on.
- **Price:** a free core lowers the barrier. Premium presets and a signal sit well below the $400 to $2,000 band.

Options 2 and 3 are not only "better" because they are cheaper. Competitors can copy price, but not a verified track record or a clean compliance record. Those must be earned.

## 6. Product requirements for the recommended position

Prioritised. Each item must pass the test in section 7 before it counts as done.

**P0: safety and correctness (blocks everything else)**
1. Set a magic number and restrict all position and order management to it.
2. Compile in MetaEditor (or via a CI job using MetaEditor under Wine) and fix every warning.
3. Add a licence file (MIT, per the README) so the open-source position is real.

**P1: risk controls (prop-firm rules)**
4. Risk-based lot sizing: a percentage of equity, with the existing fixed lot kept as the default for compatibility.
5. Daily loss and overall drawdown guard, with a kill switch that stops new orders.
6. Spread filter and maximum-trades-per-day limit.
7. News filter. MT5's built-in economic calendar (`CalendarValueHistory`) is a candidate; confirm it works in the terminal before relying on it.

**P2: evidence**
8. Backtest protocol: XAUUSD, every-tick with real spread, in-sample and out-of-sample split, reporting max drawdown, profit factor, trades per month and worst day.
9. Demo forward test for at least 3 months, then a small live account. Publish a verified signal.

**P3: product**
10. Setfiles for common account sizes and prop-firm profiles.
11. A minimal on-chart panel showing status, daily P&L and the kill-switch state.
12. Install guide, FAQ, and a clear risk disclosure in every release.
13. Distribution: free core on GitHub, premium presets on the MQL5 Market.

## 7. Go / no-go gates

- **Before any paid release:** P0 complete, compiled, and tested on a demo account.
- **Before claiming any performance:** out-of-sample results on a prop-firm profile must show a profit factor above 1.2 and a max drawdown within the firm's limit. If not, revise the strategy or stop.
- **Before selling:** a verified signal with at least 3 months of live or demo history, and the regulator checks in section 3 done.
- **Kill criteria:** if out-of-sample profit factor stays at or below 1.0, or the live record breaches the drawdown limit twice, stop selling and publish the findings.

## 8. Risks and limitations

- **Sources.** Many competitor figures come from affiliate and seller blogs. Ratings, review counts and prices should be rechecked on the product pages before use. The MQL5 listing figures come from a single snapshot.
- **No competitor performance was verified.** Live signals of competitors were not checked; their claims are self-reported.
- **Compilation and backtests were not run.** This audit is desk research and a code review. The recommended gates exist because the code's performance is unknown.
- **Not financial, legal or tax advice.** Trading gold with leverage carries a substantial risk of loss. Any commercial sale needs local legal review, including Botswana rules.

## 9. Sources

1. Algorithmic Trading Market report (2025 value $24.06bn, CAGR 12.88%): https://www.theinsightpartners.com/reports/algorithm-trading-market
2. Algorithmic Trading System Market report (2025 value $21.8bn, retail share 16.3%): https://dataintelo.com/report/algorithmic-trading-system-market
3. Finance Magnates via TradingView, MT5 share of retail CFD volume on MetaQuotes platforms, Q3 2025: https://www.tradingview.com/news/financemagnates:9ea4aa5f4094b:0-mt5-extends-its-lead-over-mt4-as-platform-shift-accelerates/
4. PropFirmMap, platform support across 53 prop firms, 2026: https://propfirmmap.com/blog/prop-firm-platforms-mt5-ctrader-match-trader-compared-2026
5. MQL5 Market, Expert Advisors listing (fetched 2026-11-02): https://www.mql5.com/en/market/mt5/expert
6. MetaTrader 5 Help, How to become a seller (20% commission, $30 minimum, rentals): https://www.metatrader5.com/en/terminal/help/market/market_sell
7. MQL5 Market rules (no profitability guarantee, no refunds, device binding): https://www.mql5.com/en/market/rules
8. NewYorkCityServers, best MT5 EAs (affiliate blog, unverified): https://newyorkcityservers.com/blog/best-mt5-expert-advisors
9. MQL5 Wall, free and bestselling products (Gold Session Portfolio, GOLD SNIPING): https://www.mql5.com/en/wall
10. QuantVPS, best automated trading platforms 2026: https://www.quantvps.com/blog/best-automated-trading-platform
11. Techiefied, TradingView vs MetaTrader (PineConnector price): https://techiefied.com/tradingview-vs-metatrader/
12. BrokersRoom, platform reviews 2026: https://brokersroom.trade/platform-reviews
13. FCA warning on unauthorised social-media "investment experts" offering signals (BrokersView): https://www.fastbull.com/brokersview/news/fca-warning-investment-experts-on-social-media-are-not-authorized-by-the-regulator-304895
14. About Forex Markets, machine trading and regulator warnings: https://www.aboutforexmarkets.com/forex-machine-trading.php
15. TopBrokers360, forex scam warning signs 2026: https://www.topbrokers360.com/featured/forex-scam-warning-signs-fake-broker-checklist-2026/
16. Nordman Algorithms, prop firm EA rules and account closures 2026: https://www.nordman-algorithms.com/prop-firm-ea-rules-automated-trading-banned/
17. Funded Trading, EA policy comparison by prop firm 2026: https://fundedtrading.com/prop-firms-for-expert-advisors-ea-trading/
18. EAFunded, FTMO EA rules 2026: https://www.eafunded.com/firms/ftmo
