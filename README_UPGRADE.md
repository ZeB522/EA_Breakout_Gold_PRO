# EA Breakout Gold - v3.00 Upgrade Notes

Esta versão contém a evolução do EA Breakout Gold para tornar o sistema mais robusto para operar XAUUSD.

Resumo das mudanças
- Confirmação de rompimento apenas após fechamento do candle (reduz falsos breakouts).
- Filtros de tendência (EMA50 + EMA200) e confirmação de força com ADX.
- Ignora rompimentos em canais muito estreitos (MinChannelWidthPoints).
- Filtro de volume via iVolume quando disponível.
- Stop Loss, Take Profit e Trailing baseados em ATR; trailing agressivo após 2R.
- Fechamento parcial (50% em 1R) e Break-even inteligente.
- Dimensionamento de lote por risco real (opção para usar AccountEquity).
- Limite diário de perda e de lucro; limite de trades por dia; limite de perdas consecutivas.
- Modo Conservador (exige todos os filtros).
- Sessões configuráveis (London / NewYork / ambos / custom); filtro de spread e bloqueio em janelas de notícias.
- Retry/resiliência em OrderSend/OrderModify; logging mais detalhado.
- Parâmetros expostos para otimização no Strategy Tester; código modularizado.

Instruções rápidas
1. Abra `EA_Breakout_Gold_PRO.mq4` (branch `feature/robust-breakout-xau`) no MetaEditor e compile; corrija alerts/warnings caso sua corretora requira ajustes.
2. Teste em Strategy Tester com dados de tick de qualidade (Dukascopy ou histórico confiável) e spreads realistas.
3. Teste em conta demo com lotes baixos por algumas semanas antes de usar em real.

Parâmetros novos principais (inputs expostos)
- RangeCandles, EMAPeriodFast, EMAPeriodSlow, ADXPeriod, ADXThreshold
- MinChannelWidthPoints, UseVolumeFilter, VolumeAvgPeriod, VolumeMultiplier
- ATRMultiplierSL, ATRMultiplierTP, ATRTrailingMultiplier
- PartialCloseRatio, AggressiveTrailingAfterR
- RiskPercent, UseEquityForRisk, MaxDailyDrawdown, DailyProfitLimitPercent
- MaxTradesPerDay, MaxConsecutiveLosses, ConservativeMode
- TradingSession (preset), CustomSessionStartH / EndH
- RetryOrderSendCount, RetryDelayMs

Ranges de otimização recomendados (exemplos)
- ATRMultiplierSL: 1.5 – 3.0 (step 0.1)
- ATRMultiplierTP: 2.0 – 4.0 (step 0.1)
- ADXThreshold: 18 – 30 (step 1)
- RangeCandles: 20 – 80 (step 5)
- MinChannelWidthPoints: 30 – 120 (step 10)
- RiskPercent: 0.10 – 1.00 (% por trade) (step 0.05)
- VolumeMultiplier: 1.0 – 2.0 (step 0.1)

Notas técnicas
- As horas de sessão (London/NY) são presets heurísticos; ajuste conforme o fuso do servidor de sua corretora.
- O EA grava logs em arquivo; no Strategy Tester o File I/O pode ter comportamento diferente.
- Integração com calendário de notícias não foi implementada automaticamente (requer feed externo ou indicador que escreva janelas de bloqueio).

Este arquivo é um resumo. Veja o código-fonte `EA_Breakout_Gold_PRO.mq4` para detalhes de implementação e inputs.
