import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as htmlParser;
import '../../flutter_flow/flutter_flow_util.dart';

import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class DefaultRichTextWidget extends StatefulWidget {
  const DefaultRichTextWidget({
    super.key,
    required this.text,
    required this.isEdit,
    required this.controller,
  });

  final String? text;
  final bool? isEdit;
  final quill.QuillController? controller;

  @override
  State<DefaultRichTextWidget> createState() => DefaultRichTextWidgetState();
}

class DefaultRichTextWidgetState extends State<DefaultRichTextWidget> {
  quill.QuillController quillController = quill.QuillController.basic();

  @override
  void initState() {
    super.initState();
    final htmlString = widget.text ?? '';
    final quillJson = htmlToQuillJson(htmlString);

    try {
      // importante: crear un nuevo documento con el json
      final doc = quill.Document.fromJson(quillJson);
      if (widget.controller != null) {
        widget.controller!.document.replace(0, widget.controller!.document.length, doc.toDelta());
      } else {
        quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (e) {
      print('Error initializing document: $e');
    }
  }

  String? getString() {
    final controllerToUse = widget.controller ?? quillController;
    return quillJsonToHtml(controllerToUse.document.toDelta().toJson()) ?? '';
  }

  // ==========================
  // CONVERSORES HTML <-> QUILL
  // ==========================

  List<Map<String, dynamic>> htmlToQuillJson(String html) {
    final document = htmlParser.parse(html);
    final List<Map<String, dynamic>> quillJson = [];

    void parseNode(html_dom.Node node, Map<String, dynamic> parentAttributes) {
      if (node.nodeType == html_dom.Node.ELEMENT_NODE) {
        final element = node as html_dom.Element;
        final Map<String, dynamic> attributes = Map.from(parentAttributes);

        switch (element.localName) {
          case 'p':
            bool hasContent = false;
            final textContent = element.text?.trim() ?? '';
            final hasTextContent = textContent.isNotEmpty;
            final hasNonBrElements =
            element.children.any((child) => child.localName != 'br');

            if (hasTextContent || hasNonBrElements) {
              for (final child in element.nodes) {
                parseNode(child, attributes);
              }
              hasContent = true;
            }

            if (hasContent ||
                element.children.any((child) => child.localName == 'br')) {
              quillJson.add({'insert': '\n'});
            }
            return;

          case 'strong':
            attributes['bold'] = true;
            break;
          case 'em':
            attributes['italic'] = true;
            break;
          case 'ins':
            attributes['underline'] = true;
            break;
          case 'del':
          case 's':
            attributes['strike'] = true;
            break;
          case 'ul':
            _processListItems(element, quillJson, 'bullet');
            return;
          case 'ol':
            _processListItems(element, quillJson, 'ordered');
            return;
          case 'li':
            return;
          case 'br':
            quillJson.add({'insert': '\n'});
            return;
          case 'img':
            final src = element.attributes['src'];
            if (src != null) {
              quillJson.add({
                'insert': {'image': src}
              });
            }
            return;
        }

        for (final child in element.nodes) {
          parseNode(child, attributes);
        }
      } else if (node.nodeType == html_dom.Node.TEXT_NODE) {
        final text = node.text;
        if (text != null && text.trim().isNotEmpty) {
          quillJson.add({
            'insert': text.trim(),
            if (parentAttributes.isNotEmpty) 'attributes': parentAttributes,
          });
        }
      }
    }

    if (document.body != null) {
      for (final node in document.body!.nodes) {
        parseNode(node, {});
      }
    }

    final cleanedJson = <Map<String, dynamic>>[];
    for (int i = 0; i < quillJson.length; i++) {
      final current = quillJson[i];

      if (current['insert'] == '\n') {
        if (cleanedJson.length >= 2 &&
            cleanedJson[cleanedJson.length - 1]['insert'] == '\n' &&
            cleanedJson[cleanedJson.length - 2]['insert'] == '\n') {
          continue;
        }
      }

      cleanedJson.add(current);
    }

    if (cleanedJson.isEmpty || cleanedJson.last['insert'] != '\n') {
      cleanedJson.add({'insert': '\n'});
    }

    return cleanedJson;
  }

  void _processListItems(
      html_dom.Element listElement,
      List<Map<String, dynamic>> quillJson,
      String listType,
      ) {
    final listItems = listElement.querySelectorAll('li');

    for (final item in listItems) {
      final textContent = item.text?.trim() ?? '';
      if (textContent.isNotEmpty) {
        _processListItemContent(item, quillJson, listType);
      }
    }
  }

  void _processListItemContent(
      html_dom.Element liElement,
      List<Map<String, dynamic>> quillJson,
      String listType,
      ) {
    final List<Map<String, dynamic>> itemContent = [];

    void parseItemNode(
        html_dom.Node node, Map<String, dynamic> parentAttributes) {
      if (node.nodeType == html_dom.Node.ELEMENT_NODE) {
        final element = node as html_dom.Element;
        final Map<String, dynamic> attributes = Map.from(parentAttributes);

        switch (element.localName) {
          case 'strong':
            attributes['bold'] = true;
            break;
          case 'em':
            attributes['italic'] = true;
            break;
          case 'ins':
            attributes['underline'] = true;
            break;
          case 'del':
          case 's':
            attributes['strike'] = true;
            break;
          case 'br':
            itemContent.add({'insert': ' '});
            return;
        }

        for (final child in element.nodes) {
          parseItemNode(child, attributes);
        }
      } else if (node.nodeType == html_dom.Node.TEXT_NODE) {
        final text = node.text;
        if (text != null && text.trim().isNotEmpty) {
          itemContent.add({
            'insert': text.trim(),
            if (parentAttributes.isNotEmpty) 'attributes': parentAttributes,
          });
        }
      }
    }

    for (final node in liElement.nodes) {
      parseItemNode(node, {});
    }

    if (itemContent.isNotEmpty) {
      quillJson.addAll(itemContent);
      quillJson.add({
        'insert': '\n',
        'attributes': {'list': listType}
      });
    }
  }

  String quillJsonToHtml(List<dynamic> quillJson) {
    final StringBuffer htmlBuffer = StringBuffer();
    bool inList = false;
    String? currentListType;
    bool inParagraph = false;
    bool liOpen = false;

    for (int i = 0; i < quillJson.length; i++) {
      final item = quillJson[i];

      if (item.containsKey('insert')) {
        if (item['insert'] is Map && item['insert'].containsKey('image')) {
          if (liOpen) {
            htmlBuffer.write('</li>');
            liOpen = false;
          }
          if (inList) {
            htmlBuffer.write(
                currentListType == 'ordered' ? '</ol>' : '</ul>');
            inList = false;
            currentListType = null;
          }
          if (inParagraph) {
            htmlBuffer.write('</p>');
            inParagraph = false;
          }

          String imagePath = item['insert']['image'];
          String imageTag = '';

          if (imagePath.startsWith('http')) {
            imageTag = '<img src="$imagePath" alt="image" />';
          } else if (imagePath.startsWith('/')) {
            try {
              final File imageFile = File(imagePath);
              final bytes = imageFile.readAsBytesSync();
              final base64Image = base64Encode(bytes);
              imageTag =
              '<img src="data:image/jpeg;base64,$base64Image" alt="image" />';
            } catch (e) {
              imageTag = '<!-- Error loading image: $imagePath -->';
            }
          }
          htmlBuffer.write(imageTag);
        } else if (item['insert'] == '\n') {
          if (item.containsKey('attributes') &&
              item['attributes'].containsKey('list')) {
            final listType = item['attributes']['list'];

            if (inParagraph) {
              htmlBuffer.write('</p>');
              inParagraph = false;
            }

            if (liOpen) {
              htmlBuffer.write('</li>');
              liOpen = false;
            }

            if (!inList || currentListType != listType) {
              if (inList && currentListType != listType) {
                htmlBuffer.write(
                    currentListType == 'ordered' ? '</ol>' : '</ul>');
              }
              htmlBuffer.write(listType == 'ordered' ? '<ol>' : '<ul>');
              inList = true;
              currentListType = listType;
            }
          } else {
            if (liOpen) {
              htmlBuffer.write('</li>');
              liOpen = false;
            }
            if (inList) {
              htmlBuffer.write(
                  currentListType == 'ordered' ? '</ol>' : '</ul>');
              inList = false;
              currentListType = null;
            }
            if (inParagraph) {
              htmlBuffer.write('</p>');
              inParagraph = false;
            }

            if (i + 1 < quillJson.length) {
              final nextItem = quillJson[i + 1];
              if (nextItem.containsKey('insert') &&
                  nextItem['insert'] is String &&
                  nextItem['insert'].toString().trim().isNotEmpty) {
                bool nextIsListItem = false;
                if (i + 2 < quillJson.length) {
                  final nextNextItem = quillJson[i + 2];
                  if (nextNextItem['insert'] == '\n' &&
                      nextNextItem.containsKey('attributes') &&
                      nextNextItem['attributes'].containsKey('list')) {
                    nextIsListItem = true;
                  }
                }

                if (!nextIsListItem) {
                  htmlBuffer.write('<p>');
                  inParagraph = true;
                }
              }
            }
          }
        } else {
          String text = item['insert'].toString();

          if (text.trim().isEmpty) continue;

          text = text
              .replaceAll('&', '&amp;')
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;');

          bool isListItem = false;
          if (i + 1 < quillJson.length) {
            final nextItem = quillJson[i + 1];
            if (nextItem['insert'] == '\n' &&
                nextItem.containsKey('attributes') &&
                nextItem['attributes'].containsKey('list')) {
              isListItem = true;
            }
          }

          if (isListItem && !liOpen) {
            htmlBuffer.write('<li>');
            liOpen = true;
          } else if (!inList && !inParagraph && !isListItem) {
            htmlBuffer.write('<p>');
            inParagraph = true;
          }

          if (item.containsKey('attributes')) {
            final attributes = item['attributes'] as Map<String, dynamic>;
            if (attributes.containsKey('bold')) {
              text = '<strong>$text</strong>';
            }
            if (attributes.containsKey('italic')) {
              text = '<em>$text</em>';
            }
            if (attributes.containsKey('underline')) {
              text = '<ins>$text</ins>';
            }
            if (attributes.containsKey('strike')) {
              text = '<s>$text</s>';
            }
          }

          htmlBuffer.write(text);
        }
      }
    }

    if (liOpen) {
      htmlBuffer.write('</li>');
    }
    if (inList) {
      htmlBuffer.write(currentListType == 'ordered' ? '</ol>' : '</ul>');
    }
    if (inParagraph) {
      htmlBuffer.write('</p>');
    }

    return htmlBuffer.toString();
  }

  @override
  void dispose() {
    quillController.dispose();
    super.dispose();
  }

  Future<String> convertImageToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.3,
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            children: [
              /// EDITOR
              Expanded(
                child: AbsorbPointer(
                  absorbing: !(widget.isEdit ?? false),
                  child: quill.QuillEditor.basic(
                    controller: widget.controller!,
                    config: quill.QuillEditorConfig(
                      // editor en solo lectura si no es edición
                      // readOnly: !(widget.isEdit ?? false),
                      // para soportar imágenes/embeds
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                    ),
                  ),
                ),
              ),

              /// TOOLBAR (solo en modo edición)
              if (widget.isEdit ?? false)
                quill.QuillSimpleToolbar(
                  controller: widget.controller!,
                  config: quill.QuillSimpleToolbarConfig(
                    embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                    showCodeBlock: false,
                    showAlignmentButtons: false,
                    showIndent: false,
                    showCenterAlignment: false,
                    showColorButton: false,
                    showJustifyAlignment: false,
                    showQuote: false,
                    showDividers: false,
                    showRedo: false,
                    showUndo: false,
                    showListCheck: false,
                    showLink: false,
                    showSearchButton: false,
                    showListBullets: true,  // listas
                    showListNumbers: true,  // listas numeradas
                    showSubscript: false,
                    showSuperscript: false,
                    showRightAlignment: false,
                    showInlineCode: false,
                    showBackgroundColorButton: false,
                    showClearFormat: false,
                    showDirection: false,
                    showHeaderStyle: false,
                    showFontFamily: false,
                    showFontSize: false,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

}
