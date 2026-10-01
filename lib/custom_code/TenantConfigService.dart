import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Tenant fijo de este fork: la app siempre habla con `apitransportapp`.
const String kTenant = 'apitransportapp';

/// Descarga los metadatos del tenant (logos, colores, Simple App, etc.) y los
/// deja en [FFAppState].
///
/// Antes sólo corría al pulsar "Ingresar" en el splash; ahora también lo hace
/// la primera pantalla al arrancar, porque el splash ya no se muestra.
Future<void> loadTenantConfig({String tenant = kTenant}) async {
  final response = await GetOptionsPanelCall.call(tenant: tenant);

  // Obtén el campo `$.results` si existe, de lo contrario intenta con `$.data`
  final jsonFieldResults = getJsonField((response.jsonBody ?? ''), r'''$.results''');
  final jsonFieldData = (jsonFieldResults == null || jsonFieldResults.isEmpty)
      ? getJsonField((response.jsonBody ?? ''), r'''$.data''')
      : jsonFieldResults;

  String? primaryMetaColor;
  String? secondaryMetaColor;
  String? tertiaryMetaColor;

  bool foundLogoLink = false;
  bool foundFondoLink = false;
  bool foundLoaderLogo = false;
  bool foundLookerStudio = false;
  FFAppState().logoLink = '';
  FFAppState().fondoLink = '';
  FFAppState().lookerStudio = '';
  FFAppState().loaderLogo = '';

  for (var result in jsonFieldData ?? []) {
    switch (result['meta_key']) {
      case 'logo_link':
        FFAppState().logoLink = result['meta_value'].toString();
        foundLogoLink = true;
        break;
      case 'fondo_link':
        FFAppState().fondoLink = result['meta_value'].toString();
        foundFondoLink = true;
        break;
      case 'simple_app':
        FFAppState().simpleApp = result['meta_value'].toString();
        break;
      case 'role_simple_app':
        FFAppState().simpleAppRole = result['meta_value'].toString();
        break;
      case 'slug_modulo_simple_app':
        FFAppState().simpleAppSlugModule = result['meta_value'].toString();
        break;
      case 'slug_fecha_simple_app':
        FFAppState().simpleAppSlugFecha = result['meta_value'].toString();
        break;
      case 'slug_asignado_simple_app':
        FFAppState().simpleAppSlugUserAsignado =
            result['meta_value'].toString();
        break;
      case 'slug_formato_simple_app':
        FFAppState().simpleAppSlugFormato = result['meta_value'].toString();
        break;
      case 'slug_filter_simple_app':
        FFAppState().simpleSlugFilter = result['meta_value'].toString();
        break;
      case 'value_filter_simple_app':
        FFAppState().simpleValueFilter = result['meta_value'].toString();
        break;
      case 'slug_repeater_simple_app':
        FFAppState().simpleSlugRepeater = result['meta_value'].toString();
        break;
      case 'slug_repeater_label_simple_app':
        FFAppState().simpleSlugRepeaterLabel =
            result['meta_value'].toString();
        break;
      case 'slug_repeater_boolean_simple_app':
        FFAppState().simpleSlugRepeaterBoolean =
            result['meta_value'].toString();
        break;
      case 'slug_repeater_related_simple_app':
        FFAppState().simpleSlugRepeaterRelated =
            result['meta_value'].toString();
        break;
      case 'dashboard_link':
        FFAppState().lookerStudio = result['meta_value'].toString();
        foundLookerStudio = true;
        break;
      case 'app_loader_logo':
        FFAppState().loaderLogo = result['meta_value'].toString();
        foundLoaderLogo = true;
        break;
      case 'primary_color':
        primaryMetaColor = result['meta_value'].toString();
        break;
      case 'secondary_color':
        secondaryMetaColor = result['meta_value'].toString();
        break;
      case 'tertiary_color':
        tertiaryMetaColor = result['meta_value'].toString();
        break;
    }
  }

  if (!foundLogoLink) {
    FFAppState().logoLink = '';
  }

  if (!foundFondoLink) {
    FFAppState().fondoLink = '';
  }

  if (!foundLoaderLogo) {
    FFAppState().loaderLogo = '';
  }

  if (!foundLookerStudio) {
    FFAppState().lookerStudio = '';
  }

  String? newPrimaryHex = primaryMetaColor;
  String? newSecondaryHex = secondaryMetaColor;
  String? newTertiaryHex = tertiaryMetaColor;

  final prefs = await SharedPreferences.getInstance();
  final primaryHexFromPrefs = prefs.getString(kPrimaryColorKey);
  final secondaryHexFromPrefs = prefs.getString(kSecondaryColorKey);
  final tertiaryHexFromPrefs = prefs.getString(kTertiaryColorKey);

  String? primaryHexToUse;
  String? secondaryHexToUse;
  String? tertiaryHexToUse;

  if (primaryHexFromPrefs == null) {
    primaryHexToUse = newPrimaryHex ?? '92E2FFFF';
  } else {
    primaryHexToUse = newPrimaryHex ?? primaryHexFromPrefs;
  }

  if (secondaryHexFromPrefs == null) {
    secondaryHexToUse = newSecondaryHex ?? '92E2FFFF';
  } else {
    secondaryHexToUse = newSecondaryHex ?? secondaryHexFromPrefs;
  }

  if (tertiaryHexFromPrefs == null) {
    tertiaryHexToUse = newTertiaryHex ?? 'E86969';
  } else {
    tertiaryHexToUse = newTertiaryHex ?? tertiaryHexFromPrefs;
  }

  Color? primaryColor = FlutterFlowTheme.getColorFromHex(primaryHexToUse);
  Color? secondaryColor = FlutterFlowTheme.getColorFromHex(secondaryHexToUse);
  Color? tertiaryColor = FlutterFlowTheme.getColorFromHex(tertiaryHexToUse);

  if (primaryColor != null &&
      secondaryColor != null &&
      tertiaryColor != null) {
    await FlutterFlowTheme.saveColors(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
    );
  }
}
