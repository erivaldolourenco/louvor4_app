import 'package:flutter/material.dart';

/// M3 emphasized-decelerate: começa rápido e assenta com uma leve
/// "ultrapassagem" (overshoot), a curva de mola característica do
/// Material 3 Expressive. Não usar em animações de opacidade (o overshoot
/// ultrapassa 1.0 e quebra a validação de `Opacity`) — reservar para escala,
/// tamanho, posição e cor/decoração.
const Curve appExpressiveCurve = Cubic(0.05, 0.7, 0.1, 1.0);
