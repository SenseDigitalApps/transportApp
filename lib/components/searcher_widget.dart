import 'package:flutter/material.dart';

import '../flutter_flow/flutter_flow_theme.dart';

class SearcherTextField extends StatelessWidget {
  final double width;
  final String hintText;
  final TextEditingController controller;
  final Function(String) onChanged;

  const SearcherTextField({
    Key? key,
    required this.width,
    required this.hintText,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width * width,
      height: 40.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: const AlignmentDirectional(0.0, 0.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: FlutterFlowTheme.of(context).primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear, color: FlutterFlowTheme.of(context).primary),
            onPressed: () {
              controller.clear();
              onChanged('');
            },
          ),
        ],
      ),
    );
  }
}