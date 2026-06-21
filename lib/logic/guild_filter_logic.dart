import '../models/boss_config.dart';

class GuildFilterLogic {
  /// Filter daftar boss berdasarkan guild yang dipilih.
  ///
  /// - `selectedGuild == null` → tampilkan semua ("All").
  /// - `selectedGuild` apapun → filter boss yang `guild`-nya cocok.
  ///   BloodMoon diperlakukan identik dengan guild lain — tidak ada logic spesial.
  static List<BossConfig> filterBosses(
    List<BossConfig> allBosses,
    Guild? selectedGuild,
  ) {
    if (selectedGuild == null) return allBosses;
    return allBosses.where((b) => b.guild == selectedGuild).toList();
  }
}
