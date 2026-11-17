import '../preview/preview_services.dart' as temporary;
import 'app_state.dart';
import 'contracts.dart';

/// Builds the services the whole app uses: the production [InOutState]
/// plus calculations, validators and the History chart.
///
/// Calculations, validators and the chart are Berre's shared work. Until her
/// implementations are merged, the preview adapters from `lib/preview/` are
/// used here so the app runs. When they are ready, replace the three
/// `temporary` values below; no screen needs to change.
AppServices createAppServices({AppState? state}) {
  final preview = temporary.createPreviewServices();
  return AppServices(
    state: state ?? InOutState(),
    calculations: preview.calculations, // TODO(Berre): production calculations
    validators: preview.validators, // TODO(Berre): production validators
    historyChartBuilder: preview.historyChartBuilder, // TODO(Berre): chart
    accentName: preview.accentName,
  );
}
