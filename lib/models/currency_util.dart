class CurrencyUtil {
  // Available currencies
  static const Map<String, CurrencyInfo> currencies = {
    'PEN': CurrencyInfo(symbol: 'S/', name: 'Soles Peruanos', code: 'PEN'),
    'USD': CurrencyInfo(symbol: '\$', name: 'US Dollar', code: 'USD'),
    'EUR': CurrencyInfo(symbol: '€', name: 'Euro', code: 'EUR'),
  };

  // Exchange rates (these should be fetched from an API in a real app)
  static const Map<String, double> exchangeRates = {
    'PEN_USD': 0.27,  // 1 PEN = 0.27 USD
    'USD_PEN': 3.70,  // 1 USD = 3.70 PEN
    'PEN_EUR': 0.25,  // 1 PEN = 0.25 EUR
    'EUR_PEN': 4.00,  // 1 EUR = 4.00 PEN
  };

  // Convert between currencies
  static double convert({
    required double amount, 
    required String fromCurrency, 
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return amount;

    final rateKey = '${fromCurrency}_$toCurrency';
    if (!exchangeRates.containsKey(rateKey)) {
      throw Exception('Exchange rate not found for $fromCurrency to $toCurrency');
    }

    return amount * exchangeRates[rateKey]!;
  }

  // Format currency with symbol
  static String format({
    required double amount, 
    required String currencyCode,
    int decimalPlaces = 2,
  }) {
    final currency = currencies[currencyCode];
    if (currency == null) {
      throw Exception('Currency code not found');
    }

    return '${currency.symbol}${amount.toStringAsFixed(decimalPlaces)}';
  }
}

// Currency information class
class CurrencyInfo {
  final String symbol;
  final String name;
  final String code;

  const CurrencyInfo({
    required this.symbol, 
    required this.name, 
    required this.code,
  });
}