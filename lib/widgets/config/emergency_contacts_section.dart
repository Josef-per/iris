import 'package:flutter/material.dart';
import 'package:iris/core/theme/app_theme.dart';

class EmergencyContactsSection extends StatelessWidget {
  const EmergencyContactsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3328174E),
            blurRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Contatos de Emerg\u{00EA}ncia',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 38),
          const _EmergencyContactCard(
            name: 'Dra. Diana',
            phone: '(16) 99999-9999',
            role: 'Psiquiatra',
          ),
          const SizedBox(height: 30),
          const _EmergencyContactCard(
            name: 'CVV',
            phone: '188',
            role: 'Urg\u{00EA}ncia',
          ),
          const SizedBox(height: 30),
          const _EmergencyContactCard(
            name: 'Papai',
            phone: '(16) 99988-9898',
            role: 'Psiquiatra',
            canRemove: true,
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _doNothing,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lavender,
                foregroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('+ Adicionar Contato'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.name,
    required this.phone,
    required this.role,
    this.canRemove = false,
  });

  final String name;
  final String phone;
  final String role;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 125,
      padding: const EdgeInsets.fromLTRB(20, 17, 9, 17),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  phone,
                  style: const TextStyle(
                    color: AppColors.deepPurple,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const _ContactAction(
            icon: Icons.phone,
            iconColor: Color(0xFF087D21),
            backgroundColor: Color(0xFFD1E5D4),
          ),
          if (canRemove) ...[
            const SizedBox(width: 7),
            const _ContactAction(
              icon: Icons.delete_outline,
              iconColor: Color(0xFFFF3040),
              backgroundColor: Color(0xFFFFE0E3),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: iconColor),
    );
  }
}

void _doNothing() {}
