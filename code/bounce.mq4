//+------------------------------------------------------------------+
//|                                                      scalper.mq4 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, LexFX."
#property link      ""
#property version   "1.00"
#property strict

#define MAGICMA  20131111
//--- input parameters
//0:fixed stop/target 1:trailing stop 2:dynamic stop/target 3:dynamic trailing stop
input int      TRADE_MODE = 1;
const /*input*/ double   TRADE_SIZE = 0.1;
input int      STOP = 360;
input int      TARGET = 300;
input int      BOUNCE_SPREAD = 340;
input double   MAX_RISK_PCT = 0.25;
const /*input*/ int      CROSS_UPPER=80;  
const /*input*/ int      CROSS_LOWER=20;
const /*input*/ bool     MARTINGALE=false;
input int      HOUR_START=7;
input int      HOUR_END=11;
const /*input*/ int ATR_PERIOD = 14;
input int MA_PERIOD = 140;

//--- Global vars
int m_bounceState = 0;
int m_crossState = 0;
double m_signalBounce = 0;
double m_signalCross = 0;
double m_trailingStop = 0;
double m_highWaterMark = 0;
double m_martingale = 1;

double GetTradeSize(double pips)
{
   double tradeSize = TRADE_SIZE;
   
   switch (TRADE_MODE) {
      case 0:
      case 1:
      case 2:
      case 3:
      {
         double tickValue = (MarketInfo(Symbol(),MODE_TICKVALUE));
         
         if(Digits == 5 || Digits == 3){
            tickValue = tickValue*10;
         }
         
         double capital = AccountBalance()*MAX_RISK_PCT/100;
         tradeSize =  NormalizeDouble(capital/pips/tickValue, 2);
         //Print("balance ",AccountBalance(),", risk ",capital,", sl_pips ",pips,", Lots ",tradeSize,", tickValue ",tickValue);
         break;
      }
   }
   
   if (MARTINGALE) {
      if (CheckLoss()) {
         m_martingale *= 2;
      } else {
         m_martingale = 1;
      }

      tradeSize = tradeSize * m_martingale;
   }
   
   return tradeSize;
}

int GetCurrentOrder()
{
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
      {
         return i;
      }
   }
   return -1;
}

bool CheckLoss()
{
   int losses=0;                        // total of losses
   int i;                               // pos of our order 
   for(i=0; i<OrdersHistoryTotal(); i++) // looping to check all of our
   {                                     // order history from pos 0 until
                                        // last pos
       if (!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) break; // is it right our order?
       if(OrderSymbol()!=Symbol() ||    // if symbol of order didn't match 
       OrderMagicNumber()!=MAGICMA) // with current chart symbol 
       continue;                        // or the magic numb of order 
                                        // didn't match with our magic
                                        // number, it is not our's, just don't check it
       if(OrderProfit()<0) losses++;    // so we count it as a losses 'cause negative profit
       else                losses=0;    // otherwise we leave it as is 
   }
   if(losses>0)  return(true);          // if last of our order is in losses
                                        // true "value" will returned from this function
   return(false);                
}

double GetBounceSignal()
{
   double lower2 = iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_LOWER,2);
   double upper2 = iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_UPPER,2);
   double lower1 = iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_LOWER,1);
   double upper1 = iBands(NULL,0,20,2,0,PRICE_CLOSE,MODE_UPPER,1);
   
   double distance = upper1 - lower1;
   
   if (Close[2] >= upper2 && Close[1] <= upper1) {
      m_signalBounce = -1;
   }
   else
   if (Close[2] <= lower2 && Close[1] >= lower1) {
      m_signalBounce = 1;
   }
   else
      m_signalBounce = 0;
      
   if (distance < (BOUNCE_SPREAD*Point)) {
     m_signalBounce = 0;
   }
      
   return m_signalBounce;
}

double GetCrossSignal()
{
   double k1 = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,1);
   double d1 = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);
   double k2 = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,2);
   double d2 = iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,2);
   
   //sell
   if (k2 > d2 && d2 >= CROSS_UPPER && k1 < d1) {
      m_signalCross = -1;//(k1 - d1);
   }
   else
   //buy
   if (k2 < d2 && d2 <= CROSS_LOWER && k1 > d1) {
      m_signalCross = 1;//(k1 - d1);
   }
   else 
      m_signalCross = 0;
      
   return m_signalCross;///SIGNAL_CROSS_MAX;
}

void CheckForOpen()
{
   double bs;
   double cs;
   double limit = 0;
   double stop = 0;
   bool positiveSlope = false;
   int currHour = TimeHour(TimeGMT());
//--- go trading only for first tiks of new bar
   if(Volume[0]>1 || currHour < HOUR_START || currHour >= HOUR_END) 
      return;
//--- get slope
   double maNow = iMA(NULL,0, MA_PERIOD, 0, MODE_SMA, PRICE_CLOSE, 1);
   double maThen = iMA(NULL,0, MA_PERIOD, 0, MODE_SMA, PRICE_CLOSE, MA_PERIOD);
   positiveSlope = maNow > maThen;
//--- get signal
   bs = GetBounceSignal();
   cs = GetCrossSignal();
   double signal = bs+cs;//numer/denom;
   int tradeSide = -1;
   Print("bounce ",bs,", cross ",cs,", slope ",positiveSlope);
   // buy
   if (signal == 2 && positiveSlope) {
      tradeSide = OP_BUY;
   } else if (signal == -2 && !positiveSlope) {
      tradeSide = OP_SELL;
   }
   
   if (tradeSide != -1) {
      ResetSignals();
      
      double tradePrice = 0;
      int limitMultiplier = 0;
      
      if (tradeSide == OP_BUY) {
         tradePrice = Ask;
         limitMultiplier = 1;
      } else if (tradeSide == OP_SELL) {
         tradePrice = Bid;
         limitMultiplier = -1;
      }
      
      switch (TRADE_MODE) {
         // fixed stop/limit
         case 0:
         {
            if (STOP > TARGET) return; //avoid negative risk/reward ratio
            limit = tradePrice + (limitMultiplier*TARGET*Point);
            stop = tradePrice - (limitMultiplier*STOP*Point);
            break;
         }
         // fixed trailing stop
         case 1:
         {
            limit = 0;
            m_trailingStop = STOP*Point;
            stop = tradePrice - (limitMultiplier*m_trailingStop);
            break;
         }
         // Dynamic stop target
         case 2:
         {
            double atrLevel = NormalizeDouble((iATR(NULL,0,ATR_PERIOD,1)*3), Digits);
            limit = tradePrice + (limitMultiplier*atrLevel);
            stop = tradePrice - (limitMultiplier*atrLevel);
            break;
         }
         // Dynamic trailing stop
         case 3:
         {
            double atrLevel = NormalizeDouble((iATR(NULL,0,ATR_PERIOD,1)*3), Digits);
            limit = 0;
            m_trailingStop = atrLevel;
            stop = tradePrice - (limitMultiplier*m_trailingStop);
            break;
         }
      }

      if (!OrderSend(Symbol(),tradeSide,GetTradeSize(MathAbs(tradePrice-stop)/Point/10),tradePrice,3,stop,limit,"",MAGICMA,0, tradeSide == OP_SELL ? Red : Blue)) {
         printf("ORDER SEND ERROR");
      }
   }
}

void ResetSignals()
{
   m_bounceState = 0;
   m_crossState = 0;
   m_signalBounce = 0;
   m_signalCross = 0;
   m_trailingStop = 0;
   m_highWaterMark = 0;
}

void TrailStop(int order)
{
   double profit = 0;
   if (OrderSelect(order,SELECT_BY_POS,MODE_TRADES))
   {
      if (OrderType()==OP_BUY)
      {
         profit = (Bid-OrderOpenPrice());
         if (profit > m_highWaterMark)
         {
            m_highWaterMark = profit;
            if (!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-m_trailingStop,OrderTakeProfit(),0,Green))
            {
               printf("BUY ORDER MODIFY ERROR");
            }
         }
      }
      else if(OrderType()==OP_SELL)
      {
         profit = (OrderOpenPrice()-Ask);
         if (profit > m_highWaterMark)
         {
            m_highWaterMark = profit;
            if (!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+m_trailingStop,OrderTakeProfit(),0,Red))
            {
               printf("SELL ORDER MODIFY ERROR");
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
//--- check for history and trading
   if(Bars < 100 || IsTradeAllowed() == false)
      return;
// check time

   int orderId = GetCurrentOrder();
   if(orderId == -1) {
      CheckForOpen();
   } else if (TRADE_MODE == 1 || TRADE_MODE == 3) {                                    
      TrailStop(orderId);
   }
//---
 }
//+------------------------------------------------------------------+
