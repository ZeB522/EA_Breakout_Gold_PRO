Resumo

Refactor completo e melhorias para tornar o EA Breakout Gold robusto para XAUUSD.

Principais mudanças:
- Confirmação de breakout somente após fechamento de candle.
- Filtros de tendência (EMA50 + EMA200) e força (ADX).
- Ignora canais muito estreitos; filtro de volume (quando disponível).
- SL/TP, trailing e trailing agressivo baseados em ATR.
- Partial close (50% em 1R); break‑even inteligente.
- Gestão de risco: lot sizing por risco real (opção de usar AccountEquity), limite diário de perda e lucro, limite de operações por dia e perdas consecutivas.
- Modo Conservador (exige concordância de todos os filtros).
- Sessões configuráveis (London/NY/ambas/custom), filtros de spread e bloqueio em janelas de notícias.
- Retries para OrderSend/OrderModify e logging detalhado.

Observações:
- Compile no MetaEditor e verifique warnings/erros antes de testar.
- Teste em Strategy Tester com ticks de qualidade e em demo antes de usar em real.

Checklist antes do merge:
- [ ] Compilar sem erros no MetaEditor
- [ ] Backtest com dados de tick (Dukascopy) — verificar lucros, DD, número de trades
- [ ] Forward test em demo por pelo menos 2 semanas
- [ ] Ajustar horas de sessão conforme fuso do servidor
- [ ] Revisar logs e tratamento de erros no ambiente do broker
