import 'dart:convert';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imagen
import 'dart:io'; // Para manejar archivos
import 'package:intl/intl.dart';
import 'package:transport_app/app_state.dart';
import 'package:transport_app/backend/api_requests/api_calls.dart'; // Para formatear la fecha

//CERTIFICADORA QUITAR

class
NoConformidadDialog extends StatefulWidget {
  final String relational; // Recibe el prop relational
  final String label; // Recibe el prop relational
  final String format;
  final bool isManual;
  const NoConformidadDialog({Key? key,
    required this.relational,
    required this.label,
    required this.format,
    this.isManual = false,
  }) : super(key: key);

  @override
  _NoConformidadDialogState createState() => _NoConformidadDialogState();
}

class _NoConformidadDialogState extends State<NoConformidadDialog> {
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _normativaController = TextEditingController();
  File? _selectedImage; // Variable para almacenar la imagen seleccionada
  final ImagePicker _picker = ImagePicker(); // Instancia para usar el picker

  @override
  void dispose() {
    // _dateController.dispose();
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


  Future processData(Map<String, dynamic> dataToProcess09,Map<String, dynamic> dataToProcess13) async {

    String? base64Image;
    // Verificar si hay una imagen seleccionada para convertirla a Base64
    if (_selectedImage != null) {
      base64Image = await _convertImageToBase64(_selectedImage!);
    }

    // Verificar si el key "json_data" existe en el objeto principal
    if (dataToProcess09.containsKey('json_data')) {
      // Verificar si el key "rep_formato_informe_de_no_conformidades_del_servicio_de_inspeccion_ginf009" existe dentro de "json_data"
      if (!dataToProcess09['json_data'].containsKey('rep_formato_informe_de_no_conformidades_del_servicio_de_inspeccion_ginf009')) {
        // Si no existe, creamos el key con un array vacío y un mapa por defecto
        dataToProcess09['json_data']['rep_formato_informe_de_no_conformidades_del_servicio_de_inspeccion_ginf009'] = [];
      }

      int index = 0;

      // Verificar si el key "rep_2registro_fotografico_de_no_conformidad_ginf009" existe dentro de "json_data"
      if (!dataToProcess09['json_data'].containsKey('rep_2registro_fotografico_de_no_conformidad_ginf009')) {
        // Si no existe, creamos el key con un array vacío y un mapa por defecto
        dataToProcess09['json_data']['rep_2registro_fotografico_de_no_conformidad_ginf009'] = [];
      } else {
        index = dataToProcess09['json_data']['rep_2registro_fotografico_de_no_conformidad_ginf009'].length;
      }

      // Ahora agregamos un nuevo elemento al array, esté o no recién creado
      await dataToProcess09['json_data']['rep_formato_informe_de_no_conformidades_del_servicio_de_inspeccion_ginf009'].add({
        "fecha_": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "fotografia": (base64Image!=null)?"Anexo No. "+(index+1).toString():"No aplica",
        "reglamento": (widget.label!="Sin registro asociado")?widget.label.split("-")[2]:_normativaController.text,
        "no_conformidad_superada": "",
        "tipo_de_listas_de_verificacion": widget.format,
        "item_de_nc_lista_de_verificacion": (widget.label!="Sin registro asociado")?widget.label.split("-")[0]+" - "+widget.label.split("-")[1]:widget.label,
        "descripcion_de_la_no_conformidad_": _descriptionController.text
      });

      // Ahora agregamos un nuevo elemento al array, esté o no recién creado
      if(base64Image!=null){
        await dataToProcess09['json_data']['rep_2registro_fotografico_de_no_conformidad_ginf009'].add({
          "img_fotografia": base64Image ?? "",
        });
      }

    } else {

    }

    // Verificar si el key "json_data" existe en el objeto principal
    if (dataToProcess13.containsKey('json_data')) {
      // Verificar si el key "rep_formato_informe_de_no_conformidades_del_servicio_de_inspeccion_ginf009" existe dentro de "json_data"
      if (!dataToProcess13['json_data'].containsKey('rep_6_declaracion_de_no_conformidades_de_la_instalacion_electrica_inspeccionada_ginf013')) {
        // Si no existe, creamos el key con un array vacío y un mapa por defecto
        dataToProcess13['json_data']['rep_6_declaracion_de_no_conformidades_de_la_instalacion_electrica_inspeccionada_ginf013'] = [];
      }

      // Ahora agregamos un nuevo elemento al array, esté o no recién creado
      await dataToProcess13['json_data']['rep_6_declaracion_de_no_conformidades_de_la_instalacion_electrica_inspeccionada_ginf013'].add({
        "no_conformidad": _descriptionController.text+" en "+widget.format+" item "+widget.label,
      });


    } else {

    }
  }

  // Función para abrir la cámara o seleccionar imagen desde galería
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImage = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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
                const Text('No conformidad'),
                const SizedBox(height: 4), // Espacio entre el título y relational
                Text(
                  widget.format+" - Proyecto UID: "+widget.relational, // Mostrar el valor del prop relational
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  widget.label, // Mostrar el valor del prop relational
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
                  // Campo para tomar una foto o seleccionar una imagen
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200, // Hacemos el campo de imagen más grande
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: _selectedImage != null
                          ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      )
                          : const Center(
                        child: Text(
                          'Subir foto o imagen de galería',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Campo para ingresar la descripción como textarea
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3, // Esto permite que el TextField se comporte como un textarea
                  ),
                  const SizedBox(height: 10),
                if (widget.isManual) ...[
            // Campo para ingresar la normativa
                  TextField(
                    controller: _normativaController,
                    decoration: const InputDecoration(
                      labelText: 'Correo de notificación',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3, // Esto permite que el TextField se comporte como un textarea
                  ),
                  const SizedBox(height: 10),
                ],
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
                  // Lógica para guardar los datos del formulario

                  var currentData09 = await GetDataModulesCall.call(
                    tenant: FFAppState().organizacion,
                    module: "gin-f-009",
                    token: FFAppState().token,
                    moduleType: "master",
                    jsonCondition: "igual",
                    jsonKey: "ref_inspeccion_relacionada_gin-f-009",
                    jsonValue: widget.relational,
                    limit: 5,
                    page: 1,
                  );

                  var projectData = await GetDataRegistersCall.call(
                    tenant: FFAppState().organizacion,
                    token: FFAppState().token,
                    id: widget.relational
                  );

                  List<dynamic> repActasDeVisita = projectData.jsonBody["json_data"]["rep_actas_de_visita"];
                  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  // Filtrar el objeto que tenga la fecha de hoy
                  var todayObject = repActasDeVisita.firstWhere(
                        (element) => element["fecha"] == todayDate,
                    orElse: () => null, // Retorna null si no encuentra coincidencias
                  );

                  if (todayObject == null) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No hay visitas para la fecha de hoy',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).white,
                          ),
                        ),
                        duration: const Duration(milliseconds: 4000),
                        backgroundColor: FlutterFlowTheme.of(context).error,
                      ),
                    );
                    return; // Interrumpe la ejecución de la función
                  }

                  var currentData13 = await GetDataMastersCall.call(
                      tenant: FFAppState().organizacion,
                      token: FFAppState().token,
                      id: todayObject["ref_formato_diligenciado"]["value"].toString()
                  );

                  var dataToProcess09 = currentData09.jsonBody["data"][0];
                  var dataToProcess13 = currentData13.jsonBody;

                  await processData(dataToProcess09,dataToProcess13);

                  ApiCallResponse? postResult09 = await EditRegister.call(
                      tenant: FFAppState().organizacion,
                      moduleName:"gin-f-009",
                      moduleType: "master",
                      token: FFAppState().token,
                      body: jsonEncode(dataToProcess09),
                      id: currentData09.jsonBody["data"][0]["id"],
                  );

                  ApiCallResponse? postResult13 = await EditRegister.call(
                      tenant: FFAppState().organizacion,
                      moduleName:"gin-f-013",
                      moduleType: "master",
                      token: FFAppState().token,
                      body: jsonEncode(dataToProcess13),
                      id: todayObject["ref_formato_diligenciado"]["value"],
                  );

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '¡Registro realizado exitosamente!',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).white,
                        ),
                      ),
                      duration: const Duration(milliseconds: 4000),
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }



}
