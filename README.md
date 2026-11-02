# Golden Strategist EA

Experimental MetaTrader 5 Expert Advisors (MQL5) for trading gold (XAUUSD), built around an ATR-based trailing stop indicator. The code is a learning-oriented project and has **not been backtested or forward-tested in this repository**. Treat it as a starting point, not a finished trading system.

Market and competitor analysis, with sources and a prioritised roadmap: [docs/market-audit.md](docs/market-audit.md).

## Repository contents

| File | Role |
| --- | --- |
| `Golden Strategist EA_v1.mq5` | Expert Advisor, version 1. Fixed lot size (`lotSize` input, default 0.02). Wider defaults (`limitPriceGap` 200, `stopLossPips` 300). |
| `Golden Strategist EA_v2.mq5` | Expert Advisor, version 2. Lot size hardcoded to 0.02. Wider defaults (`limitPriceGap` 400, `stopLossPips` 600) and a different session window. |
| `GSRiskControls.mqh` | Shared safety helpers used by both EAs: magic-number filtering, spread check, daily-loss limit, entries-per-day count, risk-based lot sizing. **Keep it in the same folder as the EAs.** |
| `ATRStopLoss_Ind.mq5` | Custom indicator that draws ATR-based stop lines (`Up` and `Dn` buffers). Based on Rosh Jardine's ATR stop-loss indicator. Both EAs read it with `iCustom`. |
| `atr.mq5` | Standard ATR indicator (MetaQuotes sample), included as reference. |
| `Datetime.mqh` | Date/time helper struct (`CDateTime`), from MetaQuotes' standard library. Included as `<Datetime.mqh>` by the EAs. |
| `GlobalVariables.mqh` | Global-variable and synchronisation helpers (`GlobalVariable`, `Semaphore`, `AtomicVar`). Used only by the prototype in `extra/`. |
| `HMAInclude.mqh` | `CHull` class for a Hull Moving Average calculation and a `getPrice` helper. Used only by the prototype in `extra/`. |
| `extra/ATREA.mq5` | Prototype EA using the ATR stop indicator with London/New York session times. Not reviewed for trading use. |
| `extra/HMAEA.mq5` | Prototype EA that trades HMA crossovers (buy when the last closed bar crosses above the HMA, sell when it crosses below), at most once per hour, with a trailing stop. Depends on a `Hull average 2` indicator that is not in this repository, and has not been tested. |

## How the v1 and v2 Expert Advisors work

Both EAs run the same basic loop on each tick:

1. **Session filter.** Trading is allowed only inside a time window (see the differences below). Outside that window, the EA does nothing unless it already has open positions.
2. **Signal.** The last closed bar's close is compared with the indicator's `Up` line (buy) and `Dn` line (sell). A buy signal is `close > Up`; a sell signal is `close < Dn`.
3. **Entry.** When a signal appears and the EA is allowed to place an order, it places a **stop order** `limitPriceGap` above the ask (buy) or below the bid (sell), with a stop loss `stopLossPips` away. Only one order cycle runs at a time.
4. **Pending-order cleanup.** Buy/sell stop orders older than 5 minutes (300 seconds) are deleted.
5. **Trailing.** Each open position's stop loss is moved to the current indicator line when it changes.

Units: `limitPriceGap` and `stopLossPips` are multiplied by `_Point`, so they are in **points** (broker price increments), not pips.

Known differences between v1 and v2:

- **Session window.** v1 trades between 08:00 and 22:00 and v2 between 12:00 and 15:00, both on the broker's **server time**. The code comments describe these times as GMT, but the code does not convert them, so the windows will shift with your broker's server offset.
- **Lot size.** v1 reads it from an input. v2 hardcodes 0.02.
- **Defaults.** See the table above.

## Safety settings (both EAs)

Each EA has these inputs. Defaults keep the original behaviour, except that trade tagging and position management are now limited to the EA's own orders.

| Input | Default | Effect |
| --- | --- | --- |
| `InpMagicNumber` | v1: 26110201, v2: 26110202 | Tags this EA's orders. The EA only manages orders and positions with its own symbol and magic number, so manual trades and other EAs are left alone. Give each EA on the same account a different number. |
| `InpMaxSpreadPoints` | 0 (off) | No new entries while the spread is above this many points. |
| `InpRiskPercent` | 0 (off) | When above 0, the lot size is set so that the stop-loss distance risks this percentage of equity. If the broker's minimum lot would exceed that risk, the EA skips the trade. When 0, the fixed lot size is used (`lotSize` in v1, 0.02 in v2 unless changed). |
| `InpMaxDailyLossPct` | 0 (off) | No new entries once equity has fallen by this percentage of day-start equity (broker server day). Open trades are **not** closed. The reference equity is reset when the EA restarts mid-day. |
| `InpMaxEntriesPerDay` | 0 (off) | Caps new entries (filled orders) per broker server day. |

**Upgrading from an earlier version:** positions and pending orders opened by the earlier builds used magic number 0. The new builds do not manage them. Close or manage those trades manually before you switch.

**Not yet implemented:** a news filter. Prop-firm accounts often forbid new trades around high-impact news, so do not use this EA on such an account until that is added.

## Installation

1. Copy `Datetime.mqh` into your terminal's `MQL5/Include/` folder. Keep `GSRiskControls.mqh` in the same folder as the EA file, because the EAs include it with quotes. `Datetime.mqh` is loaded with `<...>` syntax, so it must be in that folder or the EA will not compile.
2. Compile `ATRStopLoss_Ind.mq5` in MetaEditor. Both EAs call it by name, and v1/v2 also embed it with `#resource "\\ATRStopLoss_Ind.ex5"`. Check that the `.ex5` path in that line matches where MetaEditor puts the compiled file on your machine.
3. Compile the EA you want (`Golden Strategist EA_v1.mq5` or `_v2.mq5`) and attach it to an XAUUSD chart. The code does not check the symbol or timeframe. The original project notes say H1 was the intended timeframe.
4. Test on a demo account first.

## Status and known issues

- Compilation has **not** been verified: this environment has no MetaEditor. The code has been syntax-checked with a C++ parser, which catches structural errors but not type or name errors. Compile in MetaEditor before use.
- The `#resource` path and `iCustom` name depend on your installation (see step 2 above).
- Session-time comments say GMT, but the code uses broker server time (see above).
- `extra/` contains unfinished prototypes. They are not maintained alongside the v1/v2 EAs.
- The repository has no `LICENSE` file. An older version of this README said the project is MIT-licensed, but no license text is included, so confirm the terms with the author before reusing the code.

## Risk warning

Automated trading can lose money quickly, including the full account balance. Test thoroughly on a demo account before any live use. This project comes with no warranty and no guarantee of profit.
