import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imagen
import 'package:transport_app/backend/api_requests/api_calls.dart';
import 'dart:io';
import 'dart:math';
import 'package:transport_app/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';

//CERTIFICADORA QUITAR

class NotificationDialog extends StatefulWidget {
  final Map<String,dynamic> idProyecto;

  const NotificationDialog({Key? key,
    required this.idProyecto,

  }) : super(key: key);

  @override
  _NotificationDialogState createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Función para convertir la imagen a Base64
  Future<String> _convertImageToBase64(File image) async {
    String encodeImage;
    String imgSend = 'data:image/jpg;base64,';
    final bytes = await image.readAsBytes(); // Leer los bytes de la imagen
    encodeImage =  base64Encode(bytes) ?? '';
    imgSend += encodeImage;
    return imgSend;
  }

  String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(rand.nextInt(chars.length))),
    );
  }


  Future processData(Map<String, dynamic> dataToProcess09,Map<String, dynamic> dataToProcess13) async {

  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Oculta el teclado al tocar fuera
      child: Center(
        child: SingleChildScrollView(
          child: AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Correo de notificación adicional'),
                const SizedBox(height: 4), // Espacio entre el título y relational
                Text(
                  "Indica un correo adicional para enviar el informe",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9, // El 90% del ancho de la pantalla
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo de destino',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 1, // Esto permite que el TextField se comporte como un textarea
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () async {
                  String existingEmails = "julianvargas@senseholding.co";
                  String newEmails = _emailController.text;
                  String updatedEmails = "$existingEmails,$newEmails";

                  var currentData09 = await GetDataModulesCall.call(
                    tenant: FFAppState().organizacion,
                    module: "gin-f-009",
                    token: FFAppState().token,
                    moduleType: "master",
                    jsonCondition: "igual",
                    jsonKey: "ref_inspeccion_relacionada_gin-f-009",
                    jsonValue: widget.idProyecto["value"],
                    limit: 5,
                    page: 1,
                  );

                  String bodyJson = jsonEncode({
                    "email_body": "A continuación encontrará el informe de no conformidades a la fecha.",
                    "email_subject": "Avance de no conformidades",
                    "destination_key": updatedEmails, // Usar los correos concatenados
                    "register_type": "masters",
                    "register_id": currentData09.jsonBody["data"][0]["id"]
                  });
                  try {
                    ApiCallResponse? postResult = await SendMailCall
                        .call(
                        tenant: FFAppState().organizacion,
                        token: FFAppState().token,
                        body: bodyJson,
                    );
                    if(postResult.succeeded){
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '¡Correo enviado exitosamente!',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).white,
                            ),
                          ),
                          duration: const Duration(milliseconds: 4000),
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                        ),
                      );
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Hubo un error enviando el correo",
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).white,
                            ),
                          ),
                          duration: const Duration(milliseconds: 4000),
                          backgroundColor: FlutterFlowTheme.of(context).error,
                        ),
                      );
                    }
                  } catch(e) {

                  }
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }



}
