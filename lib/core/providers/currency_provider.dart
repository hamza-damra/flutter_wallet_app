import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/localization_provider.dart';

class CurrencyModel {
  final String code;
  final String symbol;
  final String name;
  final String nameAr;

  const CurrencyModel({
    required this.code,
    required this.symbol,
    required this.name,
    required this.nameAr,
  });
}

const List<CurrencyModel> supportedCurrencies = [
  CurrencyModel(code: 'ILS', symbol: '₪', name: 'Israeli Shekel', nameAr: 'شيكل إسرائيلي'),
  CurrencyModel(code: 'USD', symbol: '\$', name: 'US Dollar', nameAr: 'دولار أمريكي'),
  CurrencyModel(code: 'EUR', symbol: '€', name: 'Euro', nameAr: 'يورو'),
  CurrencyModel(code: 'JOD', symbol: 'JD', name: 'Jordanian Dinar', nameAr: 'دينار أردني'),
  CurrencyModel(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound', nameAr: 'جنيه مصري'),
  CurrencyModel(code: 'SAR', symbol: 'SR', name: 'Saudi Riyal', nameAr: 'ريال سعودي'),
  CurrencyModel(code: 'AED', symbol: 'AED', name: 'UAE Dirham', nameAr: 'درهم إماراتي'),
  CurrencyModel(code: 'GBP', symbol: '£', name: 'British Pound', nameAr: 'جنيه استرليني'),
];

class CurrencyNotifier extends Notifier<CurrencyModel> {
  static const _currencyKey = 'currency_code';

  @override
  CurrencyModel build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString(_currencyKey) ?? 'ILS';
    return supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => supportedCurrencies.first,
    );
  }

  Future<void> setCurrency(CurrencyModel currency) async {
    state = currency;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_currencyKey, currency.code);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, CurrencyModel>(() {
  return CurrencyNotifier();
});
