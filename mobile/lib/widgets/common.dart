import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import 'figma_icon.dart';

/// Escudo + digital da marca.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 60, this.white = true});

  final double size;
  final bool white;

  @override
  Widget build(BuildContext context) {
    final fp = size * 0.62;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FigmaIcon(white ? AppIcons.shieldWhite : AppIcons.shieldBlue, size: size),
          // No Figma o escudo azul do login já traz a digital; o branco não.
          if (white)
            Positioned(
              left: size * 0.19,
              top: size * 0.14,
              child: FigmaIcon(AppIcons.fingerprintWhite, size: fp),
            )
          else
            FigmaIcon(AppIcons.fingerprintBlue, size: fp),
        ],
      ),
    );
  }
}

/// Quadrado colorido com iniciais (avatar dos usuários).
class InitialsBox extends StatelessWidget {
  const InitialsBox({
    super.key,
    required this.text,
    required this.color,
    this.size = 50,
    this.fontSize = 20,
    this.shadow = true,
  });

  final String text;
  final Color color;
  final double size;
  final double fontSize;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1A000000)),
        boxShadow: shadow ? AppColors.shadow : null,
      ),
      child: Text(text, style: AppText.regular(fontSize, Colors.white)),
    );
  }
}

/// Chip "6 Ativos" do cabeçalho.
class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.value, required this.label, required this.color, this.onTap});

  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tint(color),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 37,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AppText.bold(15, color)),
              const SizedBox(width: 8),
              Text(label, style: AppText.bold(15, Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de busca sobre o fundo azul-marinho.
class NavySearchField extends StatelessWidget {
  const NavySearchField({super.key, required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      decoration: BoxDecoration(
        color: AppColors.fieldOnNavy,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.shadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Row(
        children: [
          const FigmaIcon(AppIcons.search, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppText.bold(15, Colors.white),
              cursorColor: AppColors.blue,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppText.bold(15, AppColors.hintOnNavy),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de abas cinza (Todos / Ativos / ...).
class SegmentTabs extends StatelessWidget {
  const SegmentTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tabBar,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == selected ? AppColors.navy : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[i],
                      style: AppText.bold(18, i == selected ? AppColors.navy : AppColors.gray),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Card cinza das listas (usuários, ambientes, histórico).
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.child, this.onTap, this.minHeight = 94});

  final Widget child;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1A000000)),
        boxShadow: AppColors.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bolinha de status + texto ("● Operacional").
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.label, required this.color, this.size = 17});

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: AppText.regular(size, color)),
      ],
    );
  }
}

/// Carregando / erro / vazio, usados por todas as listas.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = error is ApiException ? error.toString() : 'Erro inesperado: $error';
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.gray),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: AppText.bold(15, AppColors.gray)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(message, textAlign: TextAlign.center, style: AppText.bold(15, AppColors.gray)),
        ),
      );
}

void showMessage(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.red : AppColors.navy,
    ));
}

String errorText(Object e) => e is ApiException ? e.message : 'Erro inesperado: $e';
