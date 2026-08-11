import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imagen
import 'dart:io';
import 'dart:math';
import 'package:transport_app/flutter_flow/flutter_flow_util.dart';

//CERTIFICADORA QUITAR

class
NoConformidadDialogCumplimiento extends StatefulWidget {
  final String index; // Recibe el prop relational
  final String description; // Recibe el prop relational
  final String changeIndex;
  final bool isManual;
  final Function(String, String, String, FFUploadedFile) updateRepeaterField;

  const NoConformidadDialogCumplimiento({Key? key,
    required this.index,
    required this.description,
    required this.changeIndex,
    this.isManual = false,
    required this.updateRepeaterField,

  }) : super(key: key);

  @override
  _NoConformidadDialogCumplimientoState createState() => _NoConformidadDialogCumplimientoState();
}

class _NoConformidadDialogCumplimientoState extends State<NoConformidadDialogCumplimiento> {
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

  String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(rand.nextInt(chars.length))),
    );
  }


  Future processData(Map<String, dynamic> dataToProcess09,Map<String, dynamic> dataToProcess13) async {

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
                const Text('No conformidad evidencia'),
                const SizedBox(height: 4), // Espacio entre el título y relational
                Text(
                  widget.changeIndex+" - Proyecto UID: "+widget.index,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  widget.description,
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
                  var bytes = await _selectedImage!.readAsBytes();
                  // widget.updateRepeaterField(widget.description, widget.index, widget.changeIndex, FFUploadedFile(bytes: bytes, name:randomString(10)+".png" ) );
                  widget.updateRepeaterField(widget.description, widget.index, widget.changeIndex, FFUploadedFile(bytes: bytes, name:_selectedImage!.path.split('/').last ) );
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
