import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imagen
import 'package:transport_app/backend/api_requests/api_calls.dart';
import 'dart:io';
import 'dart:math';
import 'package:transport_app/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';

//CERTIFICADORA QUITAR

class AprobationDialog extends StatefulWidget {
  final Map<String,dynamic> dataProyecto;

  const AprobationDialog({Key? key,
    required this.dataProyecto,

  }) : super(key: key);

  @override
  _AprobationDialogState createState() => _AprobationDialogState();
}

class _AprobationDialogState extends State<AprobationDialog> {
  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
                const Text('Enviar solicitud de aumento de visitas'),
                const SizedBox(height: 4), // Espacio entre el título y relational
                Text(
                  "Indica la razón de la solicitud y la cantidad de visitas adicionales que se requieren",
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
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción de solicitud',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3, // Esto permite que el TextField se comporte como un textarea
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
                  String updatedEmails = "jc.vargas2150@gmail.com";

                  String bodyJson = jsonEncode({
                    "email_body": "El proyecto "+widget.dataProyecto["title"]+" de id "+widget.dataProyecto["consecutivo"].toString()+
                                  " ha solicitado más visitas con la siguiente descripción:\n\n"+_descriptionController.text+
                                  "\n\nIngresa a este link para realizar el procedimiento https://certificadora.itsquery.com/apps/query-table/registros?filter_module=inspecciones",
                    "email_subject": "Solicitud de aprobación de visitas proyecto "+widget.dataProyecto["title"],
                    "register_type": "registers",
                    "destination_key": updatedEmails,
                    "register_id": 288
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }



}
