//+------------------------------------------------------------------+
//|                                                  BoxBreakOut.mq4 |
//|                                http://www.goforexstrategies.com/ |
//|           Please see the website for entry and exit descriptions |
//+------------------------------------------------------------------+

extern int magicNumber = 1234;
extern double lots = 1;
extern int hourStart = 10;
extern double bufferPct = 0.3;
extern double takeProfitPct = 4;
extern double stopLossPct = 1;
extern double trailingStopPct = 1;

int slippage = 3;
double stopLoss = 0;
int ticket;
int counter;
datetime previousSignal = 0;
double buyPrice, buyTakeProfit, buySL;
double sellPrice, sellTakeProfit, sellSL;
double trailingStopPips;
datetime expiration;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
   return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
   return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   //place pending hours daily
   if (TimeHour(TimeGMT()) == hourStart &&
       Time[0] != previousSignal)
   {
      generateSignals();
      placeBuy();
      placeSell();
      previousSignal = Time[0];
   }
   
   //monitor open trades & place trailing stops
   for(counter=0;counter<OrdersTotal();counter++)   
   {
      OrderSelect(counter, SELECT_BY_POS, MODE_TRADES);     
      if (OrderMagicNumber() == magicNumber)
      {
         //check for closing signals
         if (OrderType() == OP_BUY && OrderProfit() > 0)
         {
            checkBuyTrade();
         }
         else if (OrderType() == OP_SELL && OrderProfit() > 0)
         {
            checkSellTrade();
         }
      }
   }
   return(0);
}
//+------------------------------------------------------------------+
//| place pending BUY trade                                                  |
//+------------------------------------------------------------------+
void placeBuy()
{
   RefreshRates();            
   ticket=OrderSend(Symbol(),OP_BUYSTOP,lots,buyPrice,slippage,buySL,buyTakeProfit,"buy",magicNumber,expiration,Green);  
   if(ticket<0)
   {
      Print("BUY failed with error #",GetLastError()," at ",buyPrice);
      return;
   }
}
//+------------------------------------------------------------------+
//| place pending SELL trade                                                 |
//+------------------------------------------------------------------+
void placeSell()
{
   RefreshRates();            
   ticket=OrderSend(Symbol(),OP_SELLSTOP,lots,sellPrice,slippage,sellSL,sellTakeProfit,"sell",magicNumber,expiration,Red);  
   if(ticket<0)
   {
      Print("SELL failed with error #",GetLastError()," at ",sellPrice);
      return;
   }
}
//+------------------------------------------------------------------+
//| generate a buy & sell prices
//+------------------------------------------------------------------+
void generateSignals()
{
   double boxHeight = High[1] - Low[1];
   double bufferPips = boxHeight * bufferPct;
   double takeProfitPips = boxHeight * takeProfitPct;
   double stopLossPips = boxHeight * stopLossPct;
   trailingStopPips = boxHeight * trailingStopPct;
   
   buyPrice = NormalizeDouble(High[1] + bufferPips,Digits);
   buyTakeProfit = NormalizeDouble(High[1] + takeProfitPips,Digits);
   buySL = NormalizeDouble(buyPrice - stopLossPips,Digits);
   sellPrice = NormalizeDouble(Low[1] - bufferPips,Digits);
   sellTakeProfit = NormalizeDouble(Low[1] - takeProfitPips,Digits);
   sellSL = NormalizeDouble(sellPrice + stopLossPips,Digits);
   
   expiration = Time[0] + Period() * 60;
}
//+------------------------------------------------------------------+
//| modify trailing stop for BUY trade
//+------------------------------------------------------------------+
void checkBuyTrade()
{
   if (Bid - OrderStopLoss() > trailingStopPips)
   {
      OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid - trailingStopPips,Digits),OrderTakeProfit(),OrderExpiration(),Green);
   }
}
//+------------------------------------------------------------------+
//| modify trailing stop for SELL trade
//+------------------------------------------------------------------+
void checkSellTrade()
{
   if (OrderStopLoss() - Ask > trailingStopPips)
   {
      OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask + trailingStopPips,Digits),OrderTakeProfit(),OrderExpiration(),Red);
   }
}