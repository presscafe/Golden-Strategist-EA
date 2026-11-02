#include <Trade\Trade.mqh>
#include <Datetime.mqh>
#include "GSRiskControls.mqh"
#resource "\\ATRStopLoss_Ind.ex5"

CTrade trade;

// Define Session Times
#define LONDON_OPEN 8   // 8 AM GMT
#define LONDON_CLOSE 16 // 4 PM GMT
#define NY_OPEN 13      // 1 PM GMT
#define NY_CLOSE 22     // 10 PM GMT
#define SYDNEY_OPEN 21   // 9 PM GMT
#define SYDNEY_CLOSE 6   // 6 AM GMT
#define TOKYO_OPEN 23    // 11 PM GMT
#define TOKYO_CLOSE 8    // 8 AM GMT
#define EXCLUDED_START 16  // 4 PM GMT
#define EXCLUDED_END 20    // 8 PM GMT
#define TRADING_START 12  // 3 PM GMT
#define TRADING_END 14    // 5 PM GMT


input float InpAtrLength = 1;    // ATR Length
input float InpAtrPeriod = 5;    // ATR Period
input float InpAtrMultiplier = 1; // ATR multiplier

input float limitPriceGap = 400;
input float stopLossPips = 600.0;
input float lotSize = 0.02;     // Lot size (used when InpRiskPercent = 0)

// ---- Safety and risk controls (defaults keep the original behaviour where possible) ----
input long   InpMagicNumber      = 26110202; // Magic number: tags this EA's orders and positions
input int    InpMaxSpreadPoints  = 0;        // Max spread (points) for new entries, 0 = off
input double InpRiskPercent      = 0.0;      // Risk per trade (% of equity), 0 = use lotSize
input double InpMaxDailyLossPct  = 0.0;      // Max daily loss (% of day-start equity), 0 = off
input int    InpMaxEntriesPerDay = 0;        // Max new entries per day, 0 = off
input int    InpNewsWindowMinutes = 0;        // Block new entries within N minutes of a HIGH-impact event, 0 = off
input string InpNewsCurrency      = "USD";  // Currency whose high-impact events are checked

double lastStopLossArrayUp = -1;
double lastStopLossArrayDn = -1;
ulong buyLimitOrder = 0;
ulong sellLimitOrder = 0;
bool tradePlaced = false;
bool canPlaceBuy = true;
bool canPlaceSell = true;

ulong buyLimitTicket = 0;
ulong sellLimitTicket = 0;

datetime buyLimitTime = 0;  // Track the time BuyStop was placed
datetime sellLimitTime = 0; // Track the time SellStop was placed


//+------------------------------------------------------------------+
//| Check if it is allowed to trade according to the session times   |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
    datetime curTime = TimeCurrent();
    datetime londonOpen = LONDON_OPEN * 60 * 60;
    datetime londonClose = LONDON_CLOSE * 60 * 60;
    datetime nyOpen = NY_OPEN * 60 * 60;
    datetime nyClose = NY_CLOSE * 60 * 60;
    datetime sydneyOpen = SYDNEY_OPEN * 60 * 60;
    datetime sydneyClose = SYDNEY_CLOSE * 60 * 60;
    datetime tokyoOpen = TOKYO_OPEN * 60 * 60;
    datetime tokyoClose = TOKYO_CLOSE * 60 * 60;
    datetime excludedStart = EXCLUDED_START * 60 * 60;
    datetime excludedEnd = EXCLUDED_END * 60 * 60;
    datetime tradingStart = (TRADING_START) * 60 * 60;
    datetime tradingEnd = (TRADING_END + 1) * 60 * 60; // include the 17:00 hour

    datetime curTimeSeconds = (curTime % 86400); // seconds since midnight
    
    if (curTimeSeconds >= tradingStart && curTimeSeconds < tradingEnd)
        return true;

    return false;
}

bool CheckPositions()
{
    if(GS_CountOwnPositions(_Symbol, InpMagicNumber) > 0) // this EA's open positions
        return true; // continue with logic
    
    return false; // no open positions
}

//+------------------------------------------------------------------+
//| Expert initialisation: tag all orders with the magic number.     |
//+------------------------------------------------------------------+
int OnInit()
{
    trade.SetExpertMagicNumber((ulong)InpMagicNumber);
    return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{   
    // Expire this EA's stale pending orders first, so this runs even outside trading hours
    // Delete all pending orders older than 5 minutes (300 seconds)
    for(int i=OrdersTotal()-1; i>=0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket == 0)  // OrderGetTicket returns 0 on failure
            continue;

        ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
        if ((orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_SELL_STOP)
            && OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagicNumber)
        {
            datetime orderTime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
            if (TimeCurrent() - orderTime > 300)
            {
                trade.OrderDelete(ticket);
            }
        }
    }

    // It is outside trading hours, check for open positions
    if (!IsTradingAllowed() && !CheckPositions())
    {
        Print("Outside trading hours and no open positions. Exiting function.");
        return;
    }
    
    int rates_total = Bars(_Symbol, _Period);         // Get the number of bars in the current chart
    datetime Time[];                                  // Array to store the time values
    CopyTime(_Symbol, _Period, 0, rates_total, Time); // Copy the time values to the array
    
    Print("Trade Placed: ", tradePlaced);    // Print the value of tradePlaced
    Print("Can Place Buy: ", canPlaceBuy);   // Print the value of canPlaceBuy
    Print("Can Place Sell: ", canPlaceSell); // Print the value of canPlaceSell

    double ATRStopLossUpBuffer[2];
    double ATRStopLossDnBuffer[2];
    CopyBuffer(iCustom(_Symbol, _Period, "::ATRStopLoss_Ind.ex5", InpAtrLength, InpAtrPeriod, InpAtrMultiplier), 0, 0, 2, ATRStopLossUpBuffer);
    CopyBuffer(iCustom(_Symbol, _Period, "::ATRStopLoss_Ind.ex5", InpAtrLength, InpAtrPeriod, InpAtrMultiplier), 1, 0, 2, ATRStopLossDnBuffer);

    double closeArray[2];
    if (CopyClose(_Symbol, _Period, 0, 2, closeArray) == -1)
    {
        Print("Error copying close prices: ", GetLastError());
        return;
    }

    double currentClose = closeArray[0];

    bool validBuyCondition = (ATRStopLossUpBuffer[0] != 1.7976931348623157e+308 && currentClose > ATRStopLossUpBuffer[0]);
    bool validSellCondition = (ATRStopLossDnBuffer[0] != 1.7976931348623157e+308 && currentClose < ATRStopLossDnBuffer[0]);

    // Check if the HMA values have changed
    if (ATRStopLossUpBuffer[0] != lastStopLossArrayUp)
    {
        canPlaceBuy = true;
        lastStopLossArrayUp = ATRStopLossUpBuffer[0];
    }

    if (ATRStopLossDnBuffer[0] != lastStopLossArrayDn)
    {
        canPlaceSell = true;
        lastStopLossArrayDn = ATRStopLossDnBuffer[0];
    }
    
    if (GS_CountOwnPositions(_Symbol, InpMagicNumber) == 0 && GS_CountOwnOrders(_Symbol, InpMagicNumber) == 0)
    {
        tradePlaced = false;
    }

    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket != 0)
        {
            string symbol = PositionGetString(POSITION_SYMBOL);
            if (symbol == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
            {
                ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                switch (positionType)
                {
                case POSITION_TYPE_BUY:
                    trade.PositionModify(ticket, ATRStopLossUpBuffer[0], PositionGetDouble(POSITION_TP));
                    break;
                case POSITION_TYPE_SELL:
                    trade.PositionModify(ticket, ATRStopLossDnBuffer[0], PositionGetDouble(POSITION_TP));
                    break;
                default:
                    break;
                }
            }
        }
    }

    // ---- Entry gates: block NEW entries only; open trades are still managed ----
    bool newsBlock = GS_NewsBlocked(InpNewsWindowMinutes, InpNewsCurrency);
    if (newsBlock)   // do not let resting stop orders fill into the news spike
        GS_DeleteOwnPendingOrders(trade, _Symbol, InpMagicNumber);

    string blockReason = "";
    if (!GS_SpreadOK(_Symbol, InpMaxSpreadPoints))
        blockReason = "Entries blocked: spread above InpMaxSpreadPoints.";
    else if (newsBlock)
        blockReason = "Entries blocked: high-impact news window (InpNewsWindowMinutes).";
    else if (GS_DailyLossBreached(InpMaxDailyLossPct))
        blockReason = "Entries blocked: daily loss limit (InpMaxDailyLossPct) reached.";
    else if (InpMaxEntriesPerDay > 0 && GS_EntriesToday(_Symbol, InpMagicNumber) >= InpMaxEntriesPerDay)
        blockReason = "Entries blocked: InpMaxEntriesPerDay reached.";
    static string lastBlockReason = "";
    if (blockReason != lastBlockReason)   // log only when the state changes, not every tick
    {
        if (blockReason != "")
            Print(blockReason);
        lastBlockReason = blockReason;
    }
    bool canEnter = (blockReason == "");

    if (tradePlaced == false)
    {
        double stopLossPrice;

        if (validBuyCondition && canPlaceBuy && canEnter)
        {
            double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double BuyStopPrice = NormalizeDouble(askPrice + (limitPriceGap * _Point), _Digits); // Adjust for BuyStop
            stopLossPrice = NormalizeDouble(BuyStopPrice - (stopLossPips * _Point), _Digits);    // Calculate stop loss from BuyStopPrice

            // Ensure the BuyStopPrice is above the current market price
            if (BuyStopPrice > askPrice)
            {
                double buyVolume = GS_LotForRisk(_Symbol, InpRiskPercent, stopLossPips * _Point, lotSize);
                if (buyVolume <= 0.0)
                {
                    Print("Skipping BUY: risk budget is below the broker minimum lot.");
                }
                else
                {
                    // CTrade::BuyStop returns bool; the order ticket comes from ResultOrder()
                    if (trade.BuyStop(buyVolume, BuyStopPrice, _Symbol, stopLossPrice, 0))
                        buyLimitTicket = trade.ResultOrder();
                        // If a buy stop is placed, cancel any opposite sell stop
                        if (buyLimitTicket > 0 && sellLimitTicket > 0)
                        {
                            trade.OrderDelete(sellLimitTicket);
                            sellLimitTicket = 0;
                        }
                    else
                        Print("BuyStop failed: ", trade.ResultRetcodeDescription());

                    buyLimitTime = TimeCurrent(); // Store the time the buy stop order was placed
                    tradePlaced = true;
                    canPlaceBuy = false;
                    canPlaceSell = false;
                }
            }
        }
        else if (validSellCondition && canPlaceSell && canEnter)
        {
            double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double SellStopPrice = NormalizeDouble(bidPrice - (limitPriceGap * _Point), _Digits); // Adjust for SellStop
            stopLossPrice = NormalizeDouble(SellStopPrice + (stopLossPips * _Point), _Digits);    // Calculate stop loss from SellStopPrice

            // Ensure the SellStopPrice is below the current market price
            if (SellStopPrice < bidPrice)
            {
                double sellVolume = GS_LotForRisk(_Symbol, InpRiskPercent, stopLossPips * _Point, lotSize);
                if (sellVolume <= 0.0)
                {
                    Print("Skipping SELL: risk budget is below the broker minimum lot.");
                }
                else
                {
                    if (trade.SellStop(sellVolume, SellStopPrice, _Symbol, stopLossPrice, 0))
                        sellLimitTicket = trade.ResultOrder();
                        // If a sell stop is placed, cancel any opposite buy stop
                        if (sellLimitTicket > 0 && buyLimitTicket > 0)
                        {
                            trade.OrderDelete(buyLimitTicket);
                            buyLimitTicket = 0;
                        }
                    else
                        Print("SellStop failed: ", trade.ResultRetcodeDescription());

                    sellLimitTime = TimeCurrent(); // Store the time the sell stop order was placed
                    tradePlaced = true;
                    canPlaceSell = false;
                    canPlaceBuy = false;
                }
            }
        }
    }
}
