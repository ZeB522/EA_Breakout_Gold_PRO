#property copyright "Grok & Quant Engineer - EA Breakout Gold Robust v3.00"
#property link      ""
#property version   "3.00"
#property strict

#include <stdlib.mqh>

// ================== PARÂMETROS OPERACIONAIS & OTIMIZAÇÃO ==================
input string   S_Strategy           = "=== CONFIGURACAO DE ESTRATEGIA ===";
input int      RangeCandles         = 35;       // Período do canal histórico (candles fechados)
input int      RSIPeriod            = 14;       // Periodo RSI (se mantiver)
input double   RSIBuyLevel          = 58.0;
input double   RSISellLevel         = 42.0;
input int      EMAPeriodFast        = 50;
input int      EMAPeriodSlow        = 200;
input int      ADXPeriod            = 14;
input double   ADXThreshold         = 25.0;
input double   MinChannelWidthPoints = 60.0;    // Ignora canais estreitos (pontos)
input bool     UseVolumeFilter      = true;
input int      VolumeAvgPeriod      = 20;
input double   VolumeMultiplier     = 1.2;

input string   S_RiskManagement     = "=== GESTAO DE RISCO DE PRECISAO ===";
input double   RiskPercent          = 0.25;     // % do capital por operação (padrão)
input bool     UseEquityForRisk     = true;     // se true usa AccountEquity() em vez de balance
input double   BufferPoints         = 18.0;     // Buffer adicional para rompimento (pontos)
input double   ATRMultiplierSL      = 2.0;      // SL = ATR * ATRMultiplierSL
input double   ATRMultiplierTP      = 3.0;      // TP = ATR * ATRMultiplierTP
input double   RiskRewardRatio      = 2.8;      // (fallback se preferir R:R)
input double   MaxDailyDrawdown     = 3.0;      // % permitido sobre o capital diário
input double   DailyProfitLimitPercent = 3.0;   // % lucro diário limite para pausar operações
input double   MaxSpread            = 35.0;     // Spread max em pontos
input double   MaxMarginUsagePercent = 50.0;    // % margem por operação

input string   S_TradeManagement    = "=== GERENCIAMENTO ATIVO DE POSICAO ===";
input double   BreakevenPoints      = 180;      // Pontos de lucro para mover SL para BE
input double   TrailingStart        = 250;      // Pontos para iniciar trailing
input double   TrailingStep         = 120;      // Distância do trailing (pontos)
input double   ATRTrailingMultiplier= 1.0;      // trailing = ATR * multiplier
input double   PartialCloseRatio    = 0.5;      // fechar 50% em 1R
input double   AggressiveTrailingAfterR = 2.0;  // quando lucro > 2R usar trailing mais agressivo

input string   S_Limits             = "=== LIMITES DE OPERACOES ===";
input int      MaxConsecutiveLosses = 3;
input bool     ConservativeMode     = true;     // exige todos os filtros (EMA+ADX+Volume+RSI)
input int      MaxTradesPerDay      = 3;

input string   S_SystemParameters   = "=== CONFIGACOES DO SISTEMA ===";
input int      StartHour            = 9;        // Horario servidor (preset custom)
input int      EndHour              = 19;
input int      MagicNumber          = 1234567;
input int      Slippage             = 3;
input bool     EnableLogging        = true;
input string   LogFilePath          = "Logs/EA_Breakout_Gold_v3.00.log";

input bool     UseSessionsPresets   = true;     // usar presets de sessao
// define sessão como inteiro via enum workaround
input int      TradingSession       = 3; // 0=ALL,1=London,2=NY,3=London+NY,4=Custom
input int      CustomSessionStartH  = 9;
input int      CustomSessionEndH    = 19;

input int      RetryOrderSendCount  = 4;
input int      RetryDelayMs         = 600;

// ================== VARIÁVEIS GLOBAIS ==================
double   startOfDayEquity      = 0.0;
datetime lastDayChecked        = 0;
bool     systemHalted          = false;
bool     volatilityHalted      = false;
int      actualSlippage        = 3;
double   atrNormalReference    = 0.0;
int      totalTradesOpened     = 0;
int      totalTradesClosed     = 0;
double   totalProfitToday      = 0.0;
int      consecutiveLosses     = 0;
int      tradesToday           = 0;
int      lastProcessedBarTime  = 0;

// ================== HELPERS: Descrição de Erros ==================
string ErrorDescription(int err)
{
   switch(err)
   {
      case 0: return "NO_ERROR";
      case 1: return "ERR_NO_RESULT";
      case 2: return "ERR_COMMON_ERROR";
      case 3: return "ERR_INVALID_TRADE_PARAMETERS";
      case 4: return "ERR_SERVER_BUSY";
      case 5: return "ERR_OLD_VERSION";
      case 6: return "ERR_NO_CONNECTION";
      case 7: return "ERR_NOT_ENOUGH_RIGHTS";
      case 8: return "ERR_TOO_FREQUENT_REQUESTS";
      case 9: return "ERR_MALFUNCTIONAL_TRADE";
      case 128: return "ERR_TRADE_CONTEXT_BUSY";
      case 129: return "ERR_OLD_VERSION";
      case 130: return "ERR_NO_CONNECTION";
      case 131: return "ERR_INVALID_TRADE_PARAMETERS";
      case 132: return "ERR_TRADE_DISABLED";
      case 133: return "ERR_NOT_ENOUGH_MONEY";
      case 134: return "ERR_PRICE_CHANGED";
      case 135: return "ERR_OFF_QUOTES";
      case 136: return "ERR_BROKER_BUSY";
      case 137: return "ERR_REQUOTE";
      case 138: return "ERR_ORDER_LOCKED";
      case 139: return "ERR_LONG_POSITIONS_ONLY_ALLOWED";
      default: return IntegerToString(err);
   }
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== EA Breakout Gold Robust v3.00 - INICIADO ===");
   Print("Símbolo:", _Symbol, " TimeFrame:", _Period, " Dígitos:", _Digits);

   startOfDayEquity = AccountEquity();
   lastDayChecked = TimeCurrent();
   systemHalted = false;
   volatilityHalted = false;
   totalTradesOpened = 0;
   totalTradesClosed = 0;
   totalProfitToday = 0;
   consecutiveLosses = 0;
   tradesToday = 0;
   lastProcessedBarTime = 0;

   actualSlippage = Slippage;
   if(_Digits == 3 || _Digits == 5) actualSlippage = Slippage * 10;

   atrNormalReference = iATR(_Symbol, PERIOD_CURRENT, 14, 1);
   if(atrNormalReference > 0) Print("ATR referencia:", DoubleToString(atrNormalReference, 2));

   if(EnableLogging) {
      LogMessage("=== EA INICIADO v3.00 ===");
      LogMessage("Symbol: " + _Symbol + " Period: " + IntegerToString(_Period));
      LogMessage("Parametros: ATR SL Mult=" + DoubleToString(ATRMultiplierSL,2) + " TP Mult=" + DoubleToString(ATRMultiplierTP,2));
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   string reasonText = "Desconhecido";
   switch(reason)
   {
      case REASON_ACCOUNT: reasonText = "Mudança de Conta"; break;
      case REASON_CHARTCHANGE: reasonText = "Mudança de Gráfico"; break;
      case REASON_CHARTCLOSE: reasonText = "Gráfico Fechado"; break;
      case REASON_PARAMETERS: reasonText = "Parâmetros Modificados"; break;
      case REASON_RECOMPILE: reasonText = "Recompilação"; break;
      case REASON_REMOVE: reasonText = "Removido"; break;
      case REASON_TEMPLATE: reasonText = "Mudança de Template"; break;
   }
   Print("=== EA FINALIZADO: " + reasonText + " ===");
   if(EnableLogging) LogMessage("=== EA FINALIZADO: " + reasonText + " ===");
}

//+------------------------------------------------------------------+
//| OnTick                                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   ManageDailyState();
   if(systemHalted) {
      return;
   }

   CheckExtremeVolatility();
   if(volatilityHalted && EnableLogging) {
      return;
   }

   if(OrdersTotalByMagic() > 0)
   {
      ManageOpenOrders();
   }

   if(!IsTradingTime() || IsSpreadHigh() || IsNearHighImpactTime() || !IsSessionAllowed()) return;

   int barTime = (int)iTime(_Symbol, PERIOD_CURRENT, 1);
   if(barTime == lastProcessedBarTime) return;
   lastProcessedBarTime = barTime;

   int highestIdx = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, RangeCandles, 1);
   int lowestIdx  = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, RangeCandles, 1);

   if(highestIdx < 0 || lowestIdx < 0) {
      LogMessage("ERRO: Falha ao calcular extremos do canal");
      return;
   }

   double highRange = iHigh(_Symbol, PERIOD_CURRENT, highestIdx);
   double lowRange  = iLow(_Symbol, PERIOD_CURRENT, lowestIdx);
   double channelWidthPoints = (highRange - lowRange) / _Point;
   if(channelWidthPoints < MinChannelWidthPoints) {
      LogMessage("IGNORADO: Canal muito estreito (" + DoubleToString(channelWidthPoints,1) + " pts)");
      return;
   }

   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double rsi = iRSI(_Symbol, PERIOD_CURRENT, RSIPeriod, PRICE_CLOSE, 1);
   double emaFast = iMA(_Symbol, PERIOD_CURRENT, EMAPeriodFast, 0, MODE_EMA, PRICE_CLOSE, 1);
   double emaSlow = iMA(_Symbol, PERIOD_CURRENT, EMAPeriodSlow, 0, MODE_EMA, PRICE_CLOSE, 1);
   double adx = iADX(_Symbol, PERIOD_CURRENT, ADXPeriod, PRICE_CLOSE, MODE_MAIN, 1);
   double atr = iATR(_Symbol, PERIOD_CURRENT, 14, 1);

   bool volumeOk = true;
   if(UseVolumeFilter)
   {
      double volAvg = 0;
      int volPeriod = MathMax(1, VolumeAvgPeriod);
      for(int i=1;i<=volPeriod;i++) volAvg += iVolume(_Symbol, PERIOD_CURRENT, i);
      volAvg = volAvg / volPeriod;
      double curVol = iVolume(_Symbol, PERIOD_CURRENT, 1);
      if(volAvg > 0 && curVol < volAvg * VolumeMultiplier) volumeOk = false;
      if(!volumeOk) LogMessage("IGNORADO: Volume fraco (cur=" + DoubleToString(curVol,0) + " avg=" + DoubleToString(volAvg,0) + ")");
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   bool buyBreak = (close1 > highRange + BufferPoints * _Point);
   bool buyTrend = (emaFast > emaSlow && close1 > emaFast);
   bool buyMomentum = (adx >= ADXThreshold);
   bool buyRsi = (rsi > RSIBuyLevel);

   bool sellBreak = (close1 < lowRange - BufferPoints * _Point);
   bool sellTrend = (emaFast < emaSlow && close1 < emaFast);
   bool sellMomentum = (adx >= ADXThreshold);
   bool sellRsi = (rsi < RSISellLevel);

   bool allowBuy = buyBreak && buyTrend && buyMomentum && volumeOk && buyRsi;
   bool allowSell = sellBreak && sellTrend && sellMomentum && volumeOk && sellRsi;
   if(!ConservativeMode) {
      allowBuy = buyBreak && (buyTrend || buyMomentum) && volumeOk;
      allowSell = sellBreak && (sellTrend || sellMomentum) && volumeOk;
   }

   if(tradesToday >= MaxTradesPerDay) {
      LogMessage("Limite de trades por dia atingido: " + IntegerToString(tradesToday));
      return;
   }

   if(atr <= 0) { LogMessage("ERRO: ATR inválido"); return; }
   double stopDistPrice = atr * ATRMultiplierSL;
   double tpDistPrice = atr * ATRMultiplierTP;

   if(allowBuy)
   {
      double entryPrice = ask;
      double sl = NormalizeDouble(entryPrice - stopDistPrice, _Digits);
      double tp = NormalizeDouble(entryPrice + tpDistPrice, _Digits);

   