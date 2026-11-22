import 'app_state.dart';
import 'calculations.dart';
import 'contracts.dart';
import 'theme/app_colors.dart';
import 'validators.dart';
import 'widgets/history_chart.dart';

/// Builds the services the whole app uses: the production [InOutState],
/// calculations, validators, the History chart and accent names.
///
/// Screens only see these through `AppScope.of(context)`, so tests can pass
/// their own [state] (for example with a fixed clock).
AppServices createAppServices({AppState? state}) => AppServices(
  state: state ?? InOutState(),
  calculations: const InOutCalculations(),
  validators: const InOutValidators(),
  historyChartBuilder: buildHistoryChart,
  accentName: accentNameFor,
);
