import 'dart:convert';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import 'dart:typed_data';
import 'package:signature/signature.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:transport_app/app_state.dart';
import 'package:transport_app/backend/api_requests/api_base_url.dart';

String? validateTextField(String? value) {
  if (value == null || value.isEmpty) {
    return 'Este campo es requerido';
  }
  if (value.length < 3) {
    return 'Debe tener al menos 3 letras';
  }
  return null;
}

String buildMediaUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final org = FFAppState().organizacion;
  return ApiBaseUrl.build(tenant: org, path: path);
}

String normalizeFirmaUrl(String url) {
  if (url.isEmpty) return '';
  
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  
  if (uri.hasScheme && uri.hasAuthority) {
    return uri.path;
  }
  
  return url;
}

String extractFirmaUrlFromJson(String firmaValue) {
  if (firmaValue.isEmpty) return '';
  
  final trimmed = firmaValue.trim();
  if (!trimmed.startsWith('{')) return firmaValue;
  
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic> && decoded['url'] != null) {
      final urlValue = decoded['url'].toString();
      if (urlValue.startsWith('{')) {
        return extractFirmaUrlFromJson(urlValue);
      }
      return urlValue;
    }
  } catch (e) {
    return firmaValue;
  }
  
  return firmaValue;
}

String formatName(String word) {
  if (word.replaceAll(" ", "").toLowerCase() == "query") {
    return "api";
  } else {
    return "api" + word.replaceAll(" ", "").toLowerCase();
  }
}

Future <String> convertSignToB64 (SignatureController controller) async {
  if (controller.isEmpty) {
    return '';
  }

  final Uint8List? imageData = await controller.toPngBytes();

  if (imageData == null) {
    return '';
  }

  String base64String = base64Encode(imageData);

  String mimeType = 'image/png';

  return 'data:$mimeType;base64,$base64String';
}

bool hasPermission(
  List<String> listPermissions,
  String action,
  String moduleName,
) {
  /*listPermissions.forEach((element) {
    if (element.contains("dashboard")) {
      print(element); // Asumo que querías imprimir 'element' y no una variable 'permission' no definida.
    }
  });*/

  return listPermissions.contains("modulo.${action}_${moduleName.toLowerCase()}");
}

bool hasPermissionDashboard(
    List<String> listPermissions,
    String moduleName,
    ){

  return listPermissions.contains("admin.query_-_puede_ver_el_dashboard");
}

bool hasPermissionProcess(
    List<String> listPermissions,
    String moduleName,
    String processName,
    ){

  return listPermissions.contains("modulo.query_-_puede_acceder_a_${moduleName.toLowerCase()}_en_el_proceso_${processName.toLowerCase()}");

}

bool hasAnyPermissionForModule(
    List<String> listPermissions,
    String moduleName,
    ) {
  // Genera el prefijo basado en el módulo
  String prefix = "modulo.query_-_puede_acceder_a_${moduleName.toLowerCase()}_en_el_proceso_";

  // Verifica si existe algún permiso que comience con el prefijo
  return listPermissions.any((permission) => permission.startsWith(prefix));
}



String parseText(String text) {
  List<int> bytes = latin1.encode(text);
  String correctString = utf8.decode(bytes);

  return correctString;
}

String getShortName(String text) {
  final words = text.trim().split(RegExp(r'\s+'));
  return words.map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join();
}


IconData getIconData(String iconName) {
  switch (iconName) {
    case 'bi-alarm':
      return Icons.alarm;
    case 'bi-wifi':
      return Icons.wifi;
    case 'bi-battery':
      return Icons.battery_full;
    case 'bi-bell':
      return Icons.notifications;
    case 'bi-bookmark':
      return Icons.bookmark;
    case 'bi-camera':
      return Icons.camera_alt;
    case 'bi-cart':
      return Icons.shopping_cart;
    case 'bi-chat':
      return Icons.chat_bubble_outline;
    case 'bi-check':
      return Icons.check;
    case 'bi-clock':
      return Icons.access_time;
    case 'bi-cloud':
      return Icons.cloud_outlined;
    case 'bi-gear':
      return Icons.settings;
    case 'bi-heart':
      return Icons.favorite_border;
    case 'bi-house':
      return Icons.home_outlined;
    case 'bi-info':
      return Icons.info_outline;
    case 'bi-key':
      return Icons.vpn_key;
    case 'bi-lightning':
      return Icons.flash_on;
    case 'bi-map':
      return Icons.map_outlined;
    case 'bi-fast-forward-circle-fill':
      return Icons.fast_forward;
    case 'bi-pencil':
      return Icons.edit_outlined;
    case 'bi-arrow-up':
      return Icons.arrow_upward;
    case 'bi-arrow-down':
      return Icons.arrow_downward;
    case 'bi-arrow-left':
      return Icons.arrow_back;
    case 'bi-arrow-right':
      return Icons.arrow_forward;
    case 'bi-arrow-up-circle':
      return Icons.arrow_circle_up_outlined;
    case 'bi-arrow-down-circle':
      return Icons.arrow_circle_down_outlined;
    case 'bi-arrow-left-circle':
      return Icons.arrow_circle_left_outlined;
    case 'bi-arrow-right-circle':
      return Icons.arrow_circle_right_outlined;
    case 'bi-arrow-repeat':
      return Icons.refresh;
    case 'bi-arrows-fullscreen':
      return Icons.fullscreen;
    case 'bi-arrows-angle-contract':
      return Icons.fullscreen_exit;
    case 'bi-bar-chart':
      return Icons.bar_chart;
    case 'bi-bar-chart-line':
      return Icons.insert_chart_outlined;
    case 'bi-bar-chart-fill':
      return Icons.bar_chart;
    case 'bi-pie-chart':
      return Icons.pie_chart_outline;
    case 'bi-graph-up':
      return Icons.trending_up;
    case 'bi-graph-down':
      return Icons.trending_down;
    case 'bi-stack':
      return Icons.layers_outlined;
    case 'bi-speedometer':
      return Icons.speed;
    case 'bi-hammer':
      return Icons.handyman_outlined;
    case 'bi-tools':
      return Icons.build_outlined;
    case 'bi-wrench':
      return Icons.build_outlined;
    case 'bi-cone':
      return Icons.traffic; // Podría no ser la mejor coincidencia
    case 'bi-bricks':
      return Icons.wallpaper; // Podría no ser la mejor coincidencia
    case 'bi-screwdriver':
      return Icons.build_outlined;
    case 'bi-rulers':
      return Icons.straighten;
    case 'bi-paint-bucket':
      return Icons.format_paint_outlined;
    case 'bi-lightbulb':
      return Icons.lightbulb_outline;
    case 'bi-hospital':
      return Icons.local_hospital_outlined;
    case 'bi-clipboard-plus':
      return Icons.playlist_add; // Podría no ser la mejor coincidencia
    case 'bi-clipboard-heart':
      return Icons.favorite_border;
    case 'bi-clipboard-pulse':
      return Icons.monitor_heart_outlined;
    case 'bi-heart-pulse':
      return Icons.monitor_heart_outlined;
    case 'bi-thermometer':
      return Icons.thermostat_outlined;
    case 'bi-virus':
      return Icons.coronavirus_outlined;
    case 'bi-mask':
      return Icons.face; // Podría no ser la mejor coincidencia
    case 'bi-prescription':
      return Icons.receipt_long_outlined;
    case 'bi-droplet':
      return Icons.water_drop_outlined;
    case 'bi-eyeglasses':
      return Icons.visibility_outlined; // Podría no ser la mejor coincidencia
    case 'bi-plus-circle':
      return Icons.add_circle_outline;
    case 'bi-car-front':
      return Icons.directions_car_outlined;
    case 'bi-bus-front':
      return Icons.directions_bus_outlined;
    case 'bi-train-front':
      return Icons.directions_railway_outlined;
    case 'bi-airplane':
      return Icons.flight_outlined;
    case 'bi-truck':
      return Icons.local_shipping_outlined;
    case 'bi-truck-flatbed':
      return Icons.local_shipping_outlined;
    case 'bi-bicycle':
      return Icons.directions_bike_outlined;
    case 'bi-geo-alt':
      return Icons.place_outlined;
    case 'bi-signpost':
      return Icons.signpost_outlined;
    case 'bi-ev-station':
      return Icons.ev_station_outlined;
    case 'bi-compass':
      return Icons.compass_calibration_outlined;
    case 'bi-globe':
      return Icons.public_outlined;
    case 'bi-luggage':
      return Icons.luggage_outlined;
    case 'bi-pc':
      return Icons.desktop_windows_outlined;
    case 'bi-laptop':
      return Icons.laptop_outlined;
    case 'bi-phone':
      return Icons.smartphone_outlined;
    case 'bi-tablet':
      return Icons.tablet_android_outlined;
    case 'bi-tv':
      return Icons.tv_outlined;
    case 'bi-usb':
      return Icons.usb_outlined;
    case 'bi-broadcast':
      return Icons.wifi_tethering; // Podría no ser la mejor coincidencia
    case 'bi-headphones':
      return Icons.headphones_outlined;
    case 'bi-camera-reels':
      return Icons.photo_library_outlined; // Podría no ser la mejor coincidencia
    case 'bi-camera-video':
      return Icons.videocam_outlined;
    case 'bi-printer':
      return Icons.print_outlined;
    case 'bi-server':
      return Icons.dns_outlined;
    case 'bi-cpu':
      return Icons.memory_outlined; // Podría no ser la mejor coincidencia
    case 'bi-memory':
      return Icons.memory_outlined;
    case 'bi-router':
      return Icons.router_outlined;
    case 'bi-bluetooth':
      return Icons.bluetooth_outlined;
    case 'bi-wifi-off':
      return Icons.wifi_off_outlined;
    case 'bi-credit-card':
      return Icons.credit_card_outlined;
    case 'bi-wallet':
      return Icons.wallet_outlined;
    case 'bi-cash-stack':
      return Icons.monetization_on_outlined; // Podría no ser la mejor coincidencia
    case 'bi-currency-dollar':
      return Icons.attach_money_outlined;
    case 'bi-currency-euro':
      return Icons.euro_outlined;
    case 'bi-currency-bitcoin':
      return Icons.currency_bitcoin_outlined;
    case 'bi-receipt':
      return Icons.receipt_outlined;
    case 'bi-briefcase':
      return Icons.work_outline;
    case 'bi-graph-up-arrow':
      return Icons.trending_up; // Se usa el mismo que graph-up
    case 'bi-shop':
      return Icons.storefront_outlined;
    case 'bi-building':
      return Icons.location_city_outlined;
    case 'bi-newspaper':
      return Icons.newspaper_outlined;
    case 'bi-envelope':
      return Icons.email_outlined;
    case 'bi-chat-dots':
      return Icons.chat_bubble_outline; // Se usa similar a bi-chat
    case 'bi-chat-square':
      return Icons.chat_bubble_outline; // Se usa similar a bi-chat
    case 'bi-chat-fill':
      return Icons.chat_bubble;
    case 'bi-messenger':
      return Icons.messenger_outline;
    case 'bi-whatsapp':
      return FontAwesomeIcons.whatsapp.data;
    case 'bi-instagram':
      return FontAwesomeIcons.instagram.data;
    case 'bi-twitter':
      return FontAwesomeIcons.twitter.data;
    case 'bi-facebook':
      return FontAwesomeIcons.facebook.data;
    case 'bi-linkedin':
      return FontAwesomeIcons.linkedin.data;
    case 'bi-youtube':
      return FontAwesomeIcons.youtube.data;
    case 'bi-reddit':
      return FontAwesomeIcons.reddit.data;
    case 'bi-rss':
      return Icons.rss_feed_outlined;
    case 'bi-share':
      return Icons.share_outlined;
    case 'bi-lock':
      return Icons.lock_outline;
    case 'bi-unlock':
      return Icons.lock_open_outlined;
    case 'bi-shield':
      return Icons.security_outlined;
    case 'bi-shield-check':
      return Icons.verified_outlined;
    case 'bi-shield-exclamation':
      return Icons.warning_outlined;
    case 'bi-fingerprint':
      return Icons.fingerprint;
    case 'bi-eye-slash':
      return Icons.visibility_off_outlined;
    case 'bi-person-badge':
      return Icons.card_membership_outlined;
    case 'bi-file-lock':
      return Icons.lock_outline;
    case 'bi-award':
      return FontAwesomeIcons.award.data;
    case 'bi-trophy':
      return FontAwesomeIcons.trophy.data;
    case 'bi-flag':
      return Icons.flag_outlined;
    case 'bi-snow':
      return Icons.ac_unit_outlined;
    case 'bi-umbrella':
      return Icons.umbrella_outlined;
    case 'bi-water':
      return Icons.water_drop_outlined; // Se usa el mismo que droplet
    case 'bi-sun':
      return Icons.wb_sunny_outlined;
    case 'bi-moon':
      return Icons.nightlight_round_outlined;
    case 'bi-stopwatch':
      return Icons.timer_outlined;
    case 'bi-cup':
      return Icons.local_cafe_outlined;
    case 'bi-cup-hot':
      return Icons.local_cafe_outlined; // Se usa el mismo que cup
    case 'bi-egg':
      return Icons.egg_outlined;
    case 'bi-apple':
      return Icons.apple_outlined;
    case 'bi-basket':
      return Icons.shopping_basket_outlined;
    case 'bi-egg-fried':
      return Icons.free_breakfast_outlined; // Podría no ser la mejor coincidencia
    case 'bi-play':
      return Icons.play_arrow_outlined;
    case 'bi-pause':
      return Icons.pause_outlined;
    case 'bi-stop':
      return Icons.stop_outlined;
    case 'bi-skip-forward':
      return Icons.skip_next_outlined;
    case 'bi-skip-backward':
      return Icons.skip_previous_outlined;
    case 'bi-fast-forward':
      return Icons.fast_forward_outlined;
    case 'bi-rewind':
      return FontAwesomeIcons.backward.data;
    case 'bi-speaker':
      return Icons.speaker_outlined;
    case 'bi-volume-up':
      return Icons.volume_up_outlined;
    case 'bi-volume-down':
      return Icons.volume_down_outlined;
    case 'bi-music-note':
      return Icons.music_note_outlined;
    case 'bi-film':
      return Icons.movie_outlined;
    case 'bi-book':
      return Icons.book_outlined;
    case 'bi-journal':
      return Icons.book_outlined; // Se usa el mismo que book
    case 'bi-journal-text':
      return Icons.article_outlined;
    case 'bi-eraser':
      return Icons.delete_outline; // Podría no ser la mejor coincidencia
    case 'bi-mortarboard':
      return Icons.school_outlined;
    case 'bi-backpack':
      return Icons.backpack_outlined;
    case 'bi-question-circle':
      return Icons.question_mark_outlined;
    case 'bi-exclamation-circle':
      return Icons.error_outline;
    case 'bi-check-circle':
      return Icons.check_circle_outline;
    case 'bi-x-circle':
      return Icons.cancel_outlined;
    case 'bi-star':
      return Icons.star_border_outlined;
    case 'bi-star-fill':
      return Icons.star_outlined;
    case 'bi-fire':
      return Icons.local_fire_department_outlined;
    case 'bi-infinity':
      return FontAwesomeIcons.infinity.data;
    case 'bi-bug':
      return Icons.bug_report_outlined;
    case 'bi-clipboard-check':
      return Icons.checklist_outlined;
    case 'bi-magic':
      return FontAwesomeIcons.wandMagic.data;
    case 'bi-paperclip':
      return Icons.attach_file_outlined;
    case 'bi-clock-fill':
      return Icons.access_time; // Se usa el mismo que bi-clock
    case 'bi-recycle':
      return Icons.recycling_outlined;
    case 'bi-tree':
      return Icons.park_outlined;
    case 'bi-cloud-drizzle':
      return Icons.cloudy_snowing; // No hay coincidencia exacta
    case 'bi-cloud-lightning':
      return Icons.flash_on_outlined; // Se usa similar a lightning
    case 'bi-cloud-rain':
      return FontAwesomeIcons.cloudRain.data;
    case 'bi-wind':
      return Icons.air_outlined;
    case 'bi-sunrise':
      return Icons.wb_sunny_outlined; // Se usa el mismo que sun
    case 'bi-sunset':
      return FontAwesomeIcons.sun.data;
    case 'bi-controller':
      return Icons.gamepad_outlined;
    case 'bi-dice-1':
      return Icons.looks_one_outlined;
    case 'bi-dice-2':
      return Icons.looks_two_outlined;
    case 'bi-dice-3':
      return Icons.looks_3_outlined;
    case 'bi-dice-4':
      return Icons.looks_4_outlined;
    case 'bi-dice-5':
      return Icons.looks_5_outlined;
    case 'bi-dice-6':
      return Icons.looks_6_outlined;
    case 'bi-balloon':
      return Icons.celebration_outlined;
    case 'bi-gift':
      return Icons.card_giftcard_outlined;
    case 'bi-puzzle':
      return Icons.extension_outlined;
    case 'bi-rocket':
      return Icons.rocket_outlined;
    case 'bi-magnet':
      return FontAwesomeIcons.magnet.data;
    case 'bi-cloud-snow':
      return Icons.cloudy_snowing; // Se usa el mismo que drizzle
    case 'bi-rainbow':
      return Icons.wb_shade_outlined; // No hay coincidencia exacta
    case 'bi-thermometer-sun':
      return Icons.wb_sunny_outlined;
    default:
      return Icons.accessibility_sharp;
  }
}

bool isSignatureEmpty(SignatureController controller) {
  return controller.isEmpty;
}

Future<Uint8List?> getSignatureBinary(SignatureController controller) async {
  final Uint8List? uint8list = await controller.toPngBytes();

  if (uint8list == null) {

    return null;
  }

  return uint8list;
}

int parseIntSafely(dynamic value) {
  // Si es null, retorna 0
  if (value == null) {
    return 0;
  }

  // Si ya es un int, retorna el valor directamente
  if (value is int) {
    return value;
  }

  // Si es un string, intenta parsearlo
  if (value is String) {
    try {
      return int.parse(value);
    } catch (e) {
      // Si hay error en el parseo, retorna 0
      return 0;
    }
  }

  // Para cualquier otro tipo, retorna 0
  return 0;
}

String buildTopicFromOrganizacion() {
  final org = FFAppState().organizacion;

  if (org == 'api') {
    // Caso especial: sólo "api"
    return 'query';
  }

  if (org.startsWith('api')) {
    // Todo lo que viene después de los 3 caracteres "api"
    final anything = org.substring(3);
    return anything.isEmpty
        ? 'query'
        : anything;
  }

  return org;
}

Future<void> subscribeToOrganizacionTopic() async {
  final topic = buildTopicFromOrganizacion();
  await FirebaseMessaging.instance.subscribeToTopic(topic);
}
