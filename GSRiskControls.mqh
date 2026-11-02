//+------------------------------------------------------------------+
//| GSRiskControls.mqh                                               |
//| Shared safety helpers for the Golden Strategist EAs.             |
//|                                                                  |
//| Every helper that inspects orders or positions filters on the    |
//| EA's symbol AND magic number, so the EA never touches trades     |
//| opened manually or by other EAs.                                 |
//|                                                                  |
//| Keep this file next to the EA (the EAs include it with quotes).  |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>

//--- day tracking for the daily loss limit and entries-per-day limit
int    g_gsDayKey         = -1;
double g_gsDayStartEquity = 0.0;

//+------------------------------------------------------------------+
//| Number of open positions with this symbol and magic number.     |
//+------------------------------------------------------------------+
int GS_CountOwnPositions(const string symbol, const long magic)
{
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magic)
         n++;
   }
   return n;
}

//+------------------------------------------------------------------+
//| Number of pending orders with this symbol and magic number.     |
//+------------------------------------------------------------------+
int GS_CountOwnOrders(const string symbol, const long magic)
{
   int n = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) == symbol && OrderGetInteger(ORDER_MAGIC) == magic)
         n++;
   }
   return n;
}

//+------------------------------------------------------------------+
//| True if the current spread is within maxPoints (0 disables).    |
//+------------------------------------------------------------------+
bool GS_SpreadOK(const string symbol, const int maxPoints)
{
   if(maxPoints <= 0)
      return true;
   long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   return (spread <= maxPoints);
}

//+------------------------------------------------------------------+
//| Resets the day-start equity when the broker's server day changes.|
//| Note: after an EA restart mid-day the reference equity is        |
//| re-taken from the current equity, so restarts can loosen the     |
//| daily limit.                                                     |
//+------------------------------------------------------------------+
void GS_UpdateDay()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int key = dt.year * 10000 + dt.mon * 100 + dt.day;
   if(key != g_gsDayKey)
   {
      g_gsDayKey         = key;
      g_gsDayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   }
}

//+------------------------------------------------------------------+
//| True if equity has fallen by maxLossPct (of day-start equity)    |
//| or more. maxLossPct <= 0 disables the check.                     |
//+------------------------------------------------------------------+
bool GS_DailyLossBreached(const double maxLossPct)
{
   if(maxLossPct <= 0.0)
      return false;
   GS_UpdateDay();
   if(g_gsDayStartEquity <= 0.0)
      return false;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   return (equity <= g_gsDayStartEquity * (1.0 - maxLossPct / 100.0));
}

//+------------------------------------------------------------------+
//| Number of entry deals (fills) today for this symbol and magic.   |
//| "Today" means since broker server midnight.                      |
//+------------------------------------------------------------------+
int GS_EntriesToday(const string symbol, const long magic)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   datetime from = StructToTime(dt);
   if(!HistorySelect(from, TimeCurrent()))
      return 0;

   int n = 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;
      if(HistoryDealGetString(deal, DEAL_SYMBOL) != symbol)
         continue;
      if(HistoryDealGetInteger(deal, DEAL_MAGIC) != magic)
         continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_IN)
         n++;
   }
   return n;
}

//+------------------------------------------------------------------+
//| Number of decimal places needed for a volume step.               |
//+------------------------------------------------------------------+
int GS_VolumeDigits(const double step)
{
   int d = 0;
   double s = step;
   while(d < 8 && MathAbs(s - MathRound(s)) > 1e-9)
   {
      s *= 10.0;
      d++;
   }
   return d;
}

//+------------------------------------------------------------------+
//| Lot size for a risk-based entry.                                 |
//| riskPct <= 0: returns fallbackLot (fixed-lot mode).              |
//| Otherwise sizes so that a stop of slDistancePrice (in price      |
//| units) risks riskPct of equity. Returns 0 if the broker's minimum|
//| lot would already exceed the risk budget, so the caller skips.   |
//+------------------------------------------------------------------+
double GS_LotForRisk(const string symbol, const double riskPct, const double slDistancePrice, const double fallbackLot)
{
   if(riskPct <= 0.0)
      return fallbackLot;
   if(slDistancePrice <= 0.0)
      return 0.0;

   double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0.0 || tickValue <= 0.0)
      return 0.0;

   double riskMoney  = AccountInfoDouble(ACCOUNT_EQUITY) * riskPct / 100.0;
   double lossPerLot = (slDistancePrice / tickSize) * tickValue;
   if(lossPerLot <= 0.0)
      return 0.0;

   double lots  = riskMoney / lossPerLot;
   double step  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double minL  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxL  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0.0 || minL <= 0.0 || maxL <= 0.0)
      return 0.0;

   lots = MathFloor(lots / step) * step;
   if(lots < minL)
      return 0.0;                      // risk budget too small for the broker minimum
   if(lots > maxL)
      lots = maxL;

   return NormalizeDouble(lots, GS_VolumeDigits(step));
}

//--- news filter cache (the calendar is queried at most once per minute)
datetime g_gsNewsMinute = 0;
bool     g_gsNewsBlocked = false;

//+------------------------------------------------------------------+
//| True if a HIGH-importance economic event for 'currency' falls    |
//| within +/- windowMinutes of the current trade-server time.       |
//| windowMinutes <= 0 disables the filter.                          |
//| Fail-open: if the calendar returns no data or an error, trading  |
//| is NOT blocked. Verify the filter in your terminal before relying|
//| on it.                                                           |
//+------------------------------------------------------------------+
bool GS_NewsBlocked(const int windowMinutes, const string currency)
{
   if(windowMinutes <= 0)
      return false;

   datetime now    = TimeTradeServer();
   datetime minute = now - (now % 60);
   if(minute == g_gsNewsMinute)
      return g_gsNewsBlocked;

   bool blocked = false;
   MqlCalendarValue values[];
   int count = CalendarValueHistory(values, now - windowMinutes * 60, now + windowMinutes * 60, NULL, currency);
   if(count > 0)
   {
      for(int i = 0; i < count; i++)
      {
         MqlCalendarEvent ev;
         if(CalendarEventById(values[i].event_id, ev) && ev.importance == CALENDAR_IMPORTANCE_HIGH)
         {
            blocked = true;
            break;
         }
      }
   }

   g_gsNewsMinute  = minute;
   g_gsNewsBlocked = blocked;
   return blocked;
}

//+------------------------------------------------------------------+
//| Deletes this EA's pending stop orders (symbol + magic).          |
//| Returns the number deleted.                                      |
//+------------------------------------------------------------------+
int GS_DeleteOwnPendingOrders(CTrade &tr, const string symbol, const long magic)
{
   int deleted = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      ENUM_ORDER_TYPE ot = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if((ot == ORDER_TYPE_BUY_STOP || ot == ORDER_TYPE_SELL_STOP)
         && OrderGetString(ORDER_SYMBOL) == symbol && OrderGetInteger(ORDER_MAGIC) == magic)
      {
         if(tr.OrderDelete(ticket))
            deleted++;
      }
   }
   return deleted;
}
