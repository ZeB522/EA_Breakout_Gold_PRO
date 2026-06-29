#property copyright "Grok & Quant Engineer - EA Breakout Gold Safe & Profitable v2.03"
#property link      ""
#property version   "2.03"
#property strict

// Inclusão de biblioteca padrão para detalhamento de erros de execução
#include <stdlib.mqh>

// ================== PARÂMETROS OPERACIONAIS ==================
input string   S_Strategy           = "=== CONFIGURACAO DE ESTRATEGIA ===";
input int      RangeCandles         = 35;       // Período de determinação do canal histórico
input int      RSIPeriod            = 14;       // Período do oscilador RSI
input double   RSIBuyLevel          = 58.0;     // Gatilho de momentum de alta (RSI > N)
input double   RSISellLevel         = 42.0;     // Gatilho de momentum de baixa (RSI < N)
input double   EMAPeriod            = 200;      // Filtro de tendência macro (Média Móvel Exponencial)

input string   S_RiskManagement     = "=== GESTAO DE RISCO DE PRECISAO ===";
input double   RiskPercent          = 0.25;     // % de risco real sobre o capital por operação
input double   BufferPoints         = 18.0;     // Distância de segurança para rompimento (em pontos)
input double   ATRMultiplier        = 2.2;      // Multiplicador do ATR para cálculo do Stop Loss
input double   RiskRewardRatio      = 2.8;      // Rácio de Retorno/Risco para Take Profit
input double   MaxDailyDrawdown     = 3.0;      // % máximo de perda permitida sobre o capital diário
input double   MaxSpread            = 35.0;     // Spread máximo permitido para execução (em pontos)
input double   MaxMarginUsagePercent = 50.0;    // % máximo de margem permitida por operação

input string   S_TradeManagement    = "=== GERENCIAMENTO ATIVO DE POSICAO ===";
input double   BreakevenPoints      = 180;      // Pontos de lucro para mover o SL para o preço de entrada
input double   TrailingStart        = 250;      // Pontos de lucro para iniciar o rastreamento do Trailing Stop
input double   TrailingStep         = 120;      // Distância do Trailing Stop (em pontos)

input string   S_VolatilityControl  = "=== CONTROLE DE VOLATILIDADE EXTREMA ===";
input double   ATRNormalLevel       = 45.0;     // Seu ATR médio em condições normais (XAUUSD H1)
input double   VolatilityMultiplier = 2.5;      // Multiplicador de ATR para detectar volatilidade extrema
input bool     EnableVolatilityHalt = true;     // Parar operações se volatilidade > normal * multiplicador?

input string   S_SystemParameters   = "=== CONFIGURACOES DO SISTEMA ===";
input int      StartHour            = 9;        // Horário de início das operações (Hora do Servidor)
input int      EndHour              = 19;       // Horário de término das operações (Hora do Servidor)
input int      MagicNumber          = 123456;   // Identificador exclusivo das ordens do EA
input int      Slippage             = 3;        // Tolerância de derrapagem de preço na execução
input bool     EnableLogging        = true;     // Ativar registro detalhado de trades em arquivo?
input string   LogFilePath          = "Logs/EA_Breakout_Gold_v2.03.log";  // Caminho do arquivo de log

// Variáveis de controle de estado global
double   startOfDayBalance          = 0;
datetime lastDayChecked             = 0;
bool     systemHalted               = false;
bool     volatilityHalted           = false;
int      actualSlippage             = 3;
double   atrNormalReference         = 0;
int      totalTradesOpened          = 0;
int      totalTradesClosed          = 0;
double   totalProfitToday           = 0;

//+------------------------------------------------------------------+
//| Função de Inicialização do Expert Advisor                       |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("╔════════════════════════════════════════════════════════════╗");
   Print("║  EA Breakout Gold Safe & Profitable v2.03 - INICIADO       ║");
   Print("║  Símbolo: ", _Symbol, " | TimeFrame: ", _Period, " | Dígitos: ", _Digits);
   Print("╚════════════════════════════════════════════════════════════╝");
   
   // Inicialização do controle de drawdown diário
   startOfDayBalance = AccountBalance();
   lastDayChecked    = TimeCurrent();
   systemHalted      = false;
   volatilityHalted  = false;
   totalTradesOpened = 0;
   totalTradesClosed = 0;
   totalProfitToday  = 0;
   
   // Ajuste dinâmico de Slippage para corretoras de 3 ou 5 dígitos
   actualSlippage = Slippage;
   if(_Digits == 3 || _Digits == 5)
   {
      actualSlippage = Slippage * 10;
      Print("✓ Slippage ajustado para ", actualSlippage, " pontos (ativo com ", _Digits, " dígitos)");
   }
   
   // Captura referência de ATR normal para detecção de volatilidade
   atrNormalReference = iATR(_Symbol, PERIOD_CURRENT, 14, 1);
   if(atrNormalReference > 0)
      Print("✓ ATR de Referência Capturado: ", DoubleToString(atrNormalReference, 2));
   
   // Criar diretório de logs se não existir
   if(EnableLogging)
   {
      int pos = StringFind(LogFilePath, "/", 0);
      if(pos > 0)
      {
         string logDir = StringSubstr(LogFilePath, 0, pos);
         if(!FolderCreate(logDir))
         {
            Print("⚠ Aviso: Não foi possível criar diretório de logs: ", logDir);
         }
      }
      LogMessage("═══ EA INICIADO ═══");
      LogMessage("Símbolo: " + _Symbol + " | TimeFrame: " + IntegerToString(_Period) + " | Dígitos: " + IntegerToString(_Digits));
      LogMessage("Saldo Inicial: " + DoubleToString(startOfDayBalance, 2));
   }
   
   Print("═══════════════════════════════════════════════════════════");
   Print("Parâmetros Carregados:");
   Print("├─ Risk Per Trade: ", DoubleToString(RiskPercent, 2), "%");
   Print("├─ Max Daily Drawdown: ", DoubleToString(MaxDailyDrawdown, 2), "%");
   Print("├─ Max Spread: ", DoubleToString(MaxSpread, 2), " pontos");
   Print("├─ Trading Hours: ", StartHour, ":00 - ", EndHour, ":00 (Hora Servidor)");
   Print("├─ Volatility Halt Enabled: ", (EnableVolatilityHalt ? "SIM" : "NÃO"));
   Print("└─ Logging Enabled: ", (EnableLogging ? "SIM" : "NÃO"));
   Print("═══════════════════════════════════════════════════════════");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Função de Desinicialização do Expert Advisor                     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   string reasonText = "";
   switch(reason)
   {
      case REASON_ACCOUNT: reasonText = "Mudança de Conta"; break;
      case REASON_CHARTCHANGE: reasonText = "Mudança de Gráfico"; break;
      case REASON_CHARTCLOSE: reasonText = "Gráfico Fechado"; break;
      case REASON_PARAMETERS: reasonText = "Parâmetros Modificados"; break;
      case REASON_RECOMPILE: reasonText = "Recompilação"; break;
      case REASON_REMOVE: reasonText = "Removido"; break;
      case REASON_TEMPLATE: reasonText = "Mudança de Template"; break;
      default: reasonText = "Motivo Desconhecido"; break;
   }
   
   Print("╔════════════════════════════════════════════════════════════╗");
   Print("║  EA Breakout Gold v2.03 - FINALIZADO                       ║");
   Print("║  Razão: ", reasonText);
   Print("║  Trades Abertos: ", totalTradesOpened, " | Trades Fechados: ", totalTradesClosed);
   Print("║  Lucro Total Hoje: ", DoubleToString(totalProfitToday, 2));
   Print("╚════════════════════════════════════════════════════════════╝");
   
   if(EnableLogging)
      LogMessage("═══ EA FINALIZADO - " + reasonText + " ═══");
}

//+------------------------------------------------------------------+
//| Execução Principal - OnTick                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   // Atualiza estado do dia e analisa limite de perdas diárias
   ManageDailyState();
   if(systemHalted) 
   {
      Print("⛔ Sistema em parada de emergência (Drawdown limite atingido)");
      return;
   }
   
   // Verificação de Volatilidade Extrema (NOVO em v2.03)
   CheckExtremeVolatility();
   if(volatilityHalted && EnableVolatilityHalt)
   {
      return;
   }
   
   // Gerenciamento e acompanhamento das posições abertas
   if(OrdersTotalByMagic() > 0)
   {
      ApplyBreakeven();
      ApplyTrailingStop();
      return; // Mantém a política de segurança de uma operação por vez
   }
   
   // Filtros de segurança e horário operacional
   if(!IsTradingTime() || IsSpreadHigh() || IsNearHighImpactTime()) 
      return;
   
   // Cálculo otimizado do canal (Sem loops for de alta frequência na CPU)
   int highestIdx = iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, RangeCandles, 1);
   int lowestIdx  = iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, RangeCandles, 1);
   
   if(highestIdx == -1 || lowestIdx == -1)
   {
      LogMessage("ERRO: Falha ao calcular extremidades de preço do canal");
      return;
   }
   
   double highRange = iHigh(_Symbol, PERIOD_CURRENT, highestIdx);
   double lowRange  = iLow(_Symbol, PERIOD_CURRENT, lowestIdx);
   
   // Captura de dados analíticos
   double rsi    = iRSI(_Symbol, PERIOD_CURRENT, RSIPeriod, PRICE_CLOSE, 1);
   double ema200 = iMA(_Symbol, PERIOD_CURRENT, EMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
   double atr    = iATR(_Symbol, PERIOD_CURRENT, 14, 1);
   
   if(atr <= 0)
   {
      LogMessage("ERRO: Leitura de volatilidade ATR retornou zero");
      return;
   }
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   
   // ======================== EXECUÇÃO DE COMPRA ========================
   if(ask > (highRange + BufferPoints * _Point) && rsi > RSIBuyLevel && close1 > ema200)
   {
      double stopLossDistancePrice = atr * ATRMultiplier;
      double slPrice = NormalizeDouble(ask - stopLossDistancePrice, _Digits);
      double tpPrice = NormalizeDouble(ask + (stopLossDistancePrice * RiskRewardRatio), _Digits);
      
      // Validação de segurança contra níveis de Stop Level da corretora
      if(!ValidateStopLevels(ask, slPrice, tpPrice)) 
      {
         LogMessage("REJEIÇÃO: Stop Levels fora do permitido para BUY");
         return;
      }
      
      double calculatedLot = CalculateLot(stopLossDistancePrice);
      if(calculatedLot > 0)
      {
         int ticket = SafeOrderSend(OP_BUY, calculatedLot, ask, slPrice, tpPrice, "BUY - Breakout High");
         if(ticket > 0)
         {
            totalTradesOpened++;
            LogMessage("BUY ABERTO | Ticket: " + IntegerToString(ticket) + " | Lote: " + DoubleToString(calculatedLot, 2) 
                      + " | Entrada: " + DoubleToString(ask, _Digits) + " | SL: " + DoubleToString(slPrice, _Digits) 
                      + " | TP: " + DoubleToString(tpPrice, _Digits) + " | ATR: " + DoubleToString(atr, 2) 
                      + " | RSI: " + DoubleToString(rsi, 2));
         }
      }
   }
   
   // ======================== EXECUÇÃO DE VENDA ========================
   if(bid < (lowRange - BufferPoints * _Point) && rsi < RSISellLevel && close1 < ema200)
   {
      double stopLossDistancePrice = atr * ATRMultiplier;
      double slPrice = NormalizeDouble(bid + stopLossDistancePrice, _Digits);
      double tpPrice = NormalizeDouble(bid - (stopLossDistancePrice * RiskRewardRatio), _Digits);
      
      // Validação de segurança contra níveis de Stop Level da corretora
      if(!ValidateStopLevels(bid, slPrice, tpPrice))
      {
         LogMessage("REJEIÇÃO: Stop Levels fora do permitido para SELL");
         return;
      }
      
      double calculatedLot = CalculateLot(stopLossDistancePrice);
      if(calculatedLot > 0)
      {
         int ticket = SafeOrderSend(OP_SELL, calculatedLot, bid, slPrice, tpPrice, "SELL - Breakout Low");
         if(ticket > 0)
         {
            totalTradesOpened++;
            LogMessage("SELL ABERTO | Ticket: " + IntegerToString(ticket) + " | Lote: " + DoubleToString(calculatedLot, 2) 
                      + " | Entrada: " + DoubleToString(bid, _Digits) + " | SL: " + DoubleToString(slPrice, _Digits) 
                      + " | TP: " + DoubleToString(tpPrice, _Digits) + " | ATR: " + DoubleToString(atr, 2) 
                      + " | RSI: " + DoubleToString(rsi, 2));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Dimensionamento de Lote Profissional Baseado em Risco e Ticks    |
//+------------------------------------------------------------------+
double CalculateLot(double stopLossPriceDistance)
{
   if(stopLossPriceDistance <= 0)
   {
      LogMessage("ERRO: Distância do Stop Loss inválida para cálculo do lote");
      return 0.0;
   }

   double balance     = AccountBalance();
   double riskAmount  = balance * (RiskPercent / 100.0);
   double tickValue   = MarketInfo(_Symbol, MODE_TICKVALUE);
   double tickSize    = MarketInfo(_Symbol, MODE_TICKSIZE);
   
   if(tickValue <= 0 || tickSize <= 0)
   {
      LogMessage("ERRO CRÍTICO: Dados de variação mínima de preço indisponíveis (TickValue: " 
                + DoubleToString(tickValue, 2) + ", TickSize: " + DoubleToString(tickSize, 2) + ")");
      return 0.0;
   }
   
   // Conversão matemática precisa e independente da moeda da conta ou escala do ativo
   double stopLossTicks = stopLossPriceDistance / tickSize;
   if(stopLossTicks <= 0) 
   {
      LogMessage("ERRO: Cálculo de StopLossTicks resultou em zero");
      return 0.0;
   }
   
   double lotSize = riskAmount / (stopLossTicks * tickValue);
   
   // Ajuste obrigatório aos parâmetros permitidos pela corretora
   double minLot  = MarketInfo(_Symbol, MODE_MINLOT);
   double maxLot  = MarketInfo(_Symbol, MODE_MAXLOT);
   double lotStep = MarketInfo(_Symbol, MODE_LOTSTEP);
   
   if(lotStep <= 0) lotStep = 0.01; // Proteção contra divisão por zero de corretoras mal configuradas
   
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   
   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;
   
   // ✓ NOVO v2.03: Validação avançada de Margem Livre
   double marginRequired = MarketInfo(_Symbol, MODE_MARGINREQUIRED);
   if(marginRequired > 0)
   {
      double freeMargin = AccountFreeMargin();
      double marginNeeded = lotSize * marginRequired;
      double marginUsagePercent = (marginNeeded / AccountBalance()) * 100.0;
      
      // Rejeita se usar mais que MaxMarginUsagePercent
      if(marginUsagePercent > MaxMarginUsagePercent)
      {
         LogMessage("REJEIÇÃO: Lote " + DoubleToString(lotSize, 2) + " exigiria " 
                   + DoubleToString(marginUsagePercent, 2) + "% margem (limite: " 
                   + DoubleToString(MaxMarginUsagePercent, 2) + "%)");
         
         // Recalcula com margem máxima permitida
         lotSize = MathFloor((AccountBalance() * MaxMarginUsagePercent / 100.0) / marginRequired / lotStep) * lotStep;
      }
      
      if(freeMargin < marginNeeded)
      {
         LogMessage("REJEIÇÃO: Margem livre insuficiente. Necessária: " + DoubleToString(marginNeeded, 2) 
                   + ", Disponível: " + DoubleToString(freeMargin, 2));
         lotSize = MathFloor(freeMargin / marginRequired / lotStep) * lotStep;
         if(lotSize < minLot)
         {
            LogMessage("ERRO CRÍTICO: Margem livre insuficiente até para o lote mínimo operável");
            return 0.0;
         }
      }
   }
   
   return NormalizeDouble(lotSize, 2);
}

//+------------------------------------------------------------------+
//| Função Segura de Envio de Ordens (Padrão de Execução ECN)        |
//+------------------------------------------------------------------+
int SafeOrderSend(int type, double lot, double price, double sl, double tp, string comment)
{
   color col = (type == OP_BUY) ? clrGreen : clrRed;
   string typeStr = (type == OP_BUY) ? "BUY" : "SELL";
   
   // Passo 1: Envia a ordem a mercado com stop e alvo zerados (Requisito ECN)
   int ticket = OrderSend(_Symbol, type, lot, price, actualSlippage, 0, 0, comment, MagicNumber, 0, col);
   
   if(ticket < 0)
   {
      int errorCode = GetLastError();
      string errorDesc = ErrorDescription(errorCode);
      LogMessage("❌ FALHA NA ABERTURA | Tipo: " + typeStr + " | Erro: " + IntegerToString(errorCode) 
                + " (" + errorDesc + ") | Preço: " + DoubleToString(price, _Digits) + " | Lote: " + DoubleToString(lot, 2));
      Print("⚠ SafeOrderSend FALHA: Erro ", errorCode, " - ", errorDesc);
      return -1;
   }
   
   // Passo 2: Aplica os limites calculados imediatamente após a aprovação
   if(sl > 0 || tp > 0)
   {
      RefreshRates();
      if(!OrderModify(ticket, OrderOpenPrice(), sl, tp, 0, col))
      {
         int errorCode = GetLastError();
         string errorDesc = ErrorDescription(errorCode);
         LogMessage("⚠ WARN MODIFY | Ticket: " + IntegerToString(ticket) + " | Erro: " + IntegerToString(errorCode) 
                   + " (" + errorDesc + ") | SL: " + DoubleToString(sl, _Digits) + " | TP: " + DoubleToString(tp, _Digits));
         Print("⚠ OrderModify PARCIAL: Posição aberta #", ticket, " mas SL/TP não aplicados. Erro: ", errorCode);
      }
      else
      {
         LogMessage("✓ MODIFICAÇÃO OK | Ticket: " + IntegerToString(ticket) + " | SL: " + DoubleToString(sl, _Digits) 
                   + " | TP: " + DoubleToString(tp, _Digits));
      }
   }
   
   Print("✓ Ordem ", typeStr, " aberta com sucesso. Ticket: ", ticket, " | Lote: ", lot, " | Preço: ", DoubleToString(price, _Digits));
   return ticket;
}

//+------------------------------------------------------------------+
//| Detecção de Volatilidade Extrema (NOVO em v2.03)                |
//+------------------------------------------------------------------+
void CheckExtremeVolatility()
{
   double currentATR = iATR(_Symbol, PERIOD_CURRENT, 14, 1);
   
   if(currentATR <= 0) return;
   
   double volatilityThreshold = ATRNormalLevel * VolatilityMultiplier;
   
   if(currentATR > volatilityThreshold)
   {
      if(!volatilityHalted)
      {
         volatilityHalted = true;
         LogMessage("🔴 VOLATILIDADE EXTREMA DETECTADA | ATR: " + DoubleToString(currentATR, 2) 
                   + " > Limite: " + DoubleToString(volatilityThreshold, 2));
         Print("🔴 ALERTA: Volatilidade extrema detectada! ATR=", currentATR, " (limite=", volatilityThreshold, ")");
         
         if(EnableVolatilityHalt)
         {
            Print("   → Sistema halted até volatilidade normalizar");
            actualSlippage = Slippage * 20;  // Aumenta slippage como proteção
         }
      }
   }
   else
   {
      if(volatilityHalted)
      {
         volatilityHalted = false;
         actualSlippage = ((_Digits == 3 || _Digits == 5) ? Slippage * 10 : Slippage);
         LogMessage("🟢 VOLATILIDADE NORMALIZADA | ATR: " + DoubleToString(currentATR, 2));
         Print("🟢 Volatilidade normalizada. Sistema retomado.");
      }
   }
}

//+------------------------------------------------------------------+
//| Gerenciador Diário de Riscos de Capital e Drawdown               |
//+------------------------------------------------------------------+
void ManageDailyState()
{
   datetime curTime = TimeCurrent();
   
   // Correção de Bug Lógico: Compara ano, mês e dia individualmente para evitar falsos resets
   if(TimeDay(curTime) != TimeDay(lastDayChecked) || 
      TimeMonth(curTime) != TimeMonth(lastDayChecked) || 
      TimeYear(curTime) != TimeYear(lastDayChecked))
   {
      // Calcula lucro/prejuízo do dia anterior
      double previousDayResult = AccountEquity() - startOfDayBalance;
      totalProfitToday = previousDayResult;
      
      startOfDayBalance = AccountBalance();
      lastDayChecked    = curTime;
      systemHalted      = false;
      volatilityHalted  = false;
      totalTradesOpened = 0;
      totalTradesClosed = 0;
      
      LogMessage("═══ NOVO DIA ═══ | Saldo Base: " + DoubleToString(startOfDayBalance, 2) 
                + " | Resultado Dia Anterior: " + DoubleToString(previousDayResult, 2));
      Print("═══ NOVO DIA INICIADO ═══ | Saldo Base: ", startOfDayBalance);
   }
   
   // Verificação matemática de limite de perdas flutuantes (Drawdown)
   double currentEquity = AccountEquity();
   double allowedLossValue = startOfDayBalance * (MaxDailyDrawdown / 100.0);
   double currentDrawdown = startOfDayBalance - currentEquity;
   double drawdownPercent = (currentDrawdown / startOfDayBalance) * 100.0;
   
   if(currentEquity < (startOfDayBalance - allowedLossValue))
   {
      if(!systemHalted)
      {
         LogMessage("🛑 LIMITE DRAWDOWN DIÁRIO ATINGIDO! | Drawdown: " + DoubleToString(drawdownPercent, 2) + "% | Limite: " + DoubleToString(MaxDailyDrawdown, 2) + "%");
         Print("🛑 ALERTA CRÍTICO: Rebaixamento diário limite atingido!");
         Print("   Drawdown: ", drawdownPercent, "% | Limite: ", MaxDailyDrawdown, "%");
         CloseAllActiveOrders();
         systemHalted = true;
      }
   }
   else if(drawdownPercent > (MaxDailyDrawdown * 0.75))
   {
      // Aviso em 75% do limite
      LogMessage("⚠ ATENÇÃO: Drawdown em 75% do limite | Drawdown atual: " + DoubleToString(drawdownPercent, 2) + "%");
      Print("⚠ Atenção: Aproximando-se do limite de drawdown (", drawdownPercent, "%)");
   }
}

//+------------------------------------------------------------------+
//| Fechamento em Lote de Todas as Ordens Ativas (Procedimento Emergência) |
//+------------------------------------------------------------------+
void CloseAllActiveOrders()
{
   int closedCount = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol)
         {
            bool orderClosed = false;
            if(OrderType() == OP_BUY)
               orderClosed = OrderClose(OrderTicket(), OrderLots(), SymbolInfoDouble(_Symbol, SYMBOL_BID), actualSlippage, clrRed);
            else if(OrderType() == OP_SELL)
               orderClosed = OrderClose(OrderTicket(), OrderLots(), SymbolInfoDouble(_Symbol, SYMBOL_ASK), actualSlippage, clrRed);
               
            if(orderClosed)
            {
               closedCount++;
               LogMessage("FECHAMENTO EMERGÊNCIA | Ticket: " + IntegerToString(OrderTicket()) 
                         + " | Tipo: " + (OrderType() == OP_BUY ? "BUY" : "SELL") 
                         + " | Preço Fechamento: " + DoubleToString(OrderClosePrice(), _Digits) 
                         + " | P&L: " + DoubleToString(OrderProfit(), 2));
               totalTradesClosed++;
            }
            else
            {
               int errorCode = GetLastError();
               LogMessage("❌ FALHA FECHAMENTO | Ticket: " + IntegerToString(OrderTicket()) 
                         + " | Erro: " + IntegerToString(errorCode));
               Print("Erro crítico ao tentar encerrar ordem #", OrderTicket(), " de emergência. Código: ", errorCode);
            }
         }
      }
   }
   
   LogMessage("RESUMO FECHAMENTOS: " + IntegerToString(closedCount) + " ordens fechadas por emergência");
}

//+------------------------------------------------------------------+
//| Proteção Ativa de Lucro Mínimo: Breakeven                        |
//+------------------------------------------------------------------+
void ApplyBreakeven()
{
   double stopLevel = MarketInfo(_Symbol, MODE_STOPLEVEL) * _Point;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol)
         {
            if(OrderType() == OP_BUY)
            {
               double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               if((bid - OrderOpenPrice()) > (BreakevenPoints * _Point))
               {
                  // Só altera o stop se ele estiver abaixo do preço de abertura (entrada limpa sem loops)
                  if(OrderStopLoss() < OrderOpenPrice())
                  {
                     double targetSL = NormalizeDouble(OrderOpenPrice() + (2.0 * _Point), _Digits);
                     if((bid - targetSL) > stopLevel)
                     {
                        if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrBlue))
                        {
                           int errorCode = GetLastError();
                           LogMessage("⚠ BREAKEVEN FAIL (BUY) | Ticket: " + IntegerToString(OrderTicket()) 
                                     + " | Erro: " + IntegerToString(errorCode));
                        }
                        else
                        {
                           LogMessage("✓ BREAKEVEN APLICADO | Ticket: " + IntegerToString(OrderTicket()) 
                                     + " | Novo SL: " + DoubleToString(targetSL, _Digits));
                        }
                     }
                  }
               }
            }
            else if(OrderType() == OP_SELL)
            {
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               if((OrderOpenPrice() - ask) > (BreakevenPoints * _Point))
               {
                  // Só altera o stop se ele estiver acima do preço de abertura (ou não configurado)
                  if(OrderStopLoss() > OrderOpenPrice() || OrderStopLoss() == 0)
                  {
                     double targetSL = NormalizeDouble(OrderOpenPrice() - (2.0 * _Point), _Digits);
                     if((targetSL - ask) > stopLevel)
                     {
                        if(!OrderModify(OrderTicket(), OrderOpenPrice(), targetSL, OrderTakeProfit(), 0, clrBlue))
                        {
                           int errorCode = GetLastError();
                           LogMessage("⚠ BREAKEVEN FAIL (SELL) | Ticket: " + IntegerToString(OrderTicket()) 
                                     + " | Erro: " + IntegerToString(errorCode));
                        }
                        else
                        {
                           LogMessage("✓ BREAKEVEN APLICADO | Ticket: " + IntegerToString(OrderTicket()) 
                                     + " | Novo SL: " + DoubleToString(targetSL, _Digits));
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Rastreamento Dinâmico de Lucros: Trailing Stop                   |
//+------------------------------------------------------------------+
void ApplyTrailingStop()
{
   double stopLevel = MarketInfo(_Symbol, MODE_STOPLEVEL) * _Point;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol)
         {
            if(OrderType() == OP_BUY)
            {
               double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               if((bid - OrderOpenPrice()) > (TrailingStart * _Point))
               {
                  double proposedSL = NormalizeDouble(bid - (TrailingStep * _Point), _Digits);
                  // O Trailing Stop só pode subir a favor da operação
                  if(OrderStopLoss() < proposedSL)
                  {
                     if((bid - proposedSL) > stopLevel)
                     {
                        if(!OrderModify(OrderTicket(), OrderOpenPrice(), proposedSL, OrderTakeProfit(), 0, clrGold))
                        {
                           int errorCode = GetLastError();
                           LogMessage("⚠ TRAILING STOP FAIL (BUY) | Ticket: " + IntegerToString(OrderTicket()) 
                                     + " | Erro: " + IntegerToString(errorCode));
                        }
                        else
                        {
                           LogMessage("✓ TRAILING STOP AJUSTADO (BUY) | Ticket: " + IntegerToString(OrderTicket()) 
                                     + " | Novo SL: " + DoubleToString(proposedSL, _Digits) + " | Lucro: " + DoubleToString(bid - OrderOpenPrice(), _Digits));
                        }
                     }
                  }
               }
            }
            else if(OrderType() == OP_SELL)
            {
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               if((OrderOpenPrice() - ask) > (TrailingStart * _Point))
               {
                  double proposedSL = NormalizeDouble(ask + (TrailingStep * _Point), _Digits);
                  // O Trailing Stop só pode descer a favor da operação
                  if(OrderStopLoss() > proposedSL || OrderStopLoss() == 0)
                  {
                     if((proposedSL - ask) > stopLevel)
                     {
                        if(!OrderModify(OrderTicket(), OrderOpenPrice(), proposedSL, OrderTakeProfit(), 0, clrGold))
                        {
                           int errorCode = GetLastError();
                           LogMessage("⚠ TRAILING STOP FAIL (SELL) | Ticket: " + IntegerToString(OrderTicket()) 
                                     + " | Erro: " + IntegerToString(errorCode));
                        }
                        else
                        {
                           LogMessage("✓ TRAILING STOP AJUSTADO (SELL) | Ticket: " + IntegerToString(OrderTicket()) 
                                     + " | Novo SL: " + DoubleToString(proposedSL, _Digits) + " | Lucro: " + DoubleToString(OrderOpenPrice() - ask, _Digits));
                        }
                     }
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Filtros de Segurança Operacional Baseados em Horário             |
//+------------------------------------------------------------------+
bool IsTradingTime()
{
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   bool inTradingHours = (tm.hour >= StartHour && tm.hour < EndHour);
   
   if(!inTradingHours)
   {
      static bool lastWarningPrinted = false;
      if(!lastWarningPrinted)
      {
         LogMessage("ℹ Fora do horário de trading | Hora atual: " + IntegerToString(tm.hour) + ":" + IntegerToString(tm.min) 
                   + " | Horário permitido: " + IntegerToString(StartHour) + ":00 - " + IntegerToString(EndHour) + ":00");
         lastWarningPrinted = true;
      }
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Filtros de Spread Limit                                          |
//+------------------------------------------------------------------+
bool IsSpreadHigh()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(bid <= 0 || ask <= 0) 
   {
      LogMessage("⚠ ERRO: Cotações inválidas (BID: " + DoubleToString(bid, _Digits) 
                + ", ASK: " + DoubleToString(ask, _Digits) + ")");
      return true; // Medida preventiva contra ticks ausentes
   }
   
   double currentSpread = (ask - bid) / _Point;
   if(currentSpread > MaxSpread)
   {
      static bool lastSpreadWarningPrinted = false;
      if(!lastSpreadWarningPrinted)
      {
         LogMessage("⚠ SPREAD ALTO | Spread atual: " + DoubleToString(currentSpread, 1) + " pontos (limite: " + DoubleToString(MaxSpread, 1) + ")");
         lastSpreadWarningPrinted = true;
      }
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Filtro Ativo de Alto Impacto Macroeconômico (Notícias)           |
//+------------------------------------------------------------------+
bool IsNearHighImpactTime()
{
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   
   // Bloqueios em janelas críticas de notícias dos EUA (Hora do Servidor)
   // Geralmente às 13:30 (Payroll/CPI) e às 15:00 / 19:00 / 20:00 (Taxa de Juros/FOMC)
   // Bloqueia preventivamente 15 minutos antes e depois dos eventos macro
   if(tm.hour == 13 && tm.min >= 15 && tm.min <= 45) 
   {
      LogMessage("ℹ Período de alto impacto detectado (13:15-13:45 - CPI/Payroll)");
      return true;
   }
   if(tm.hour == 14 && tm.min >= 25 && tm.min <= 45) 
   {
      LogMessage("ℹ Período de alto impacto detectado (14:25-14:45 - Abertura NY)");
      return true;
   }
   if(tm.hour == 19 && tm.min >= 45) 
   {
      LogMessage("ℹ Período de alto impacto detectado (19:45-20:15 - Decisão Taxa/FOMC)");
      return true;
   }
   if(tm.hour == 20 && tm.min <= 15) 
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Validador Contra Níveis Mínimos de Margem Física (Stop Level)   |
//+------------------------------------------------------------------+
bool ValidateStopLevels(double entry, double sl, double tp)
{
   double stopLevel = MarketInfo(_Symbol, MODE_STOPLEVEL) * _Point;
   
   if(sl > 0 && MathAbs(entry - sl) < stopLevel)
   {
      LogMessage("ERRO: Stop Loss muito próximo (distância: " + DoubleToString(MathAbs(entry - sl) / _Point, 1) 
                + " pontos, mínimo: " + DoubleToString(stopLevel / _Point, 1) + ")");
      return false;
   }
   if(tp > 0 && MathAbs(entry - tp) < stopLevel)
   {
      LogMessage("ERRO: Take Profit muito próximo (distância: " + DoubleToString(MathAbs(entry - tp) / _Point, 1) 
                + " pontos, mínimo: " + DoubleToString(stopLevel / _Point, 1) + ")");
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Contador de Ordens Ativas por EA (Magic Number)                  |
//+------------------------------------------------------------------+
int OrdersTotalByMagic()
{
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == _Symbol)
         {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Sistema de Logging Estruturado (NOVO em v2.03)                  |
//+------------------------------------------------------------------+
void LogMessage(string message)
{
   if(!EnableLogging) return;
   
   string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   string logEntry = "[" + timestamp + "] " + message;
   
   int handle = FileOpen(LogFilePath, FILE_READ|FILE_WRITE|FILE_TXT);
   if(handle != INVALID_HANDLE)
   {
      FileSeek(handle, 0, SEEK_END);
      FileWrite(handle, logEntry);
      FileClose(handle);
   }
   else
   {
      Print("⚠ Aviso: Não foi possível abrir arquivo de log: ", LogFilePath);
   }
}

//+------------------------------------------------------------------+
// Fim do EA Breakout Gold v2.03
//+------------------------------------------------------------------+
