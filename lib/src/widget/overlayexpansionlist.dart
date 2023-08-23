import 'package:belnet_mobile/src/widget/exit_node_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

import '../model/theme_set_provider.dart';

class OverlayExpansionDropdownList extends StatefulWidget {
  final List<CustDropdownMenuItem> items;
  final Function onChanged;
  final String hintText;
  final double borderRadius;
  final double maxListHeight;
  final double borderWidth;
  final int defaultSelectedIndex;
  final bool enabled;
  final AppModel appModel;
  const OverlayExpansionDropdownList({Key? key, required this.items, required this.onChanged, required this.hintText, required this.borderRadius, required this.maxListHeight, required this.borderWidth, required this.defaultSelectedIndex, required this.enabled, required this.appModel}) : super(key: key);

  @override
  State<OverlayExpansionDropdownList> createState() => _OverlayExpansionDropdownListState();
}

class _OverlayExpansionDropdownListState extends State<OverlayExpansionDropdownList> with WidgetsBindingObserver{
bool _isOpen = false, _isAnyItemSelected = false, _isReverse = false;
  late OverlayEntry _overlayEntry;
  late RenderBox? _renderBox;
  Widget? _itemSelected;
  late Offset dropDownOffset;
  final LayerLink _layerLink = LayerLink();
  final _scrollController = ScrollController(initialScrollOffset: 0.0);


 @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          dropDownOffset = getOffset();
        });
      }
      if (widget.defaultSelectedIndex > -1) {
        if (widget.defaultSelectedIndex < widget.items.length) {
          if (mounted) {
            setState(() {
              _isAnyItemSelected = true;
              _itemSelected = widget.items[widget.defaultSelectedIndex];
              widget.onChanged(widget.items[widget.defaultSelectedIndex].value);
            });
          }
        }
      }
    });
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }


void _addOverlay() {
    if (mounted) {
      setState(() {
        _isOpen = true;
      });
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry);
  }




 void _removeOverlay() {
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
      _overlayEntry.remove();
    }
  }






OverlayEntry _createOverlayEntry() {
  _renderBox = context.findRenderObject() as RenderBox?;

    var size = _renderBox!.size;

    dropDownOffset = getOffset();

   return OverlayEntry(
    builder: (context)=> Align(   
            alignment: Alignment.center,
            child:CompositedTransformFollower(
              link: _layerLink,
               showWhenUnlinked: false,
                offset: dropDownOffset,
                child: SizedBox(
                  height: widget.maxListHeight,
                  width: size.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: _isReverse
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: <Widget>[
                      // Padding(
                      //   padding: const EdgeInsets.only(top: 10,),
                      //   child:
                      Container(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.06 / 3),
                        constraints: BoxConstraints(
                            maxHeight: widget.maxListHeight,
                            maxWidth: size.width),
                        decoration: BoxDecoration(
                            //color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(widget.borderRadius),
                          ),
                          child: Material(
                            color: widget.appModel.darkTheme
                                ? Color(0xFF242430)
                                : Color(0xFFF9F9F9),
                            elevation: 0,
                            shadowColor: Colors.grey,
                            child: RawScrollbar(
                              thumbColor: widget.appModel.darkTheme
                                  ? Color(0xff4D4D64)
                                  : Color(0xffC7C7C7),
                              thumbVisibility: true,
                              controller: _scrollController,
                              thickness: 3.6,
                              child: Container()
                              
                            ),
                          ),
                        ),
                      ),
                      // ),
                    ],
                  ),
                ), 
              
            )
    )
    
    );

}





























  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.enabled
            ? () {
                _isOpen ? _removeOverlay() : _addOverlay();
              }
            : null,
        child: Container(
          decoration: _getDecoration(),
          child: Row(
            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Container(
                  // flex: 3,
                  child: _isAnyItemSelected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: _itemSelected!,
                        )
                      : Padding(
                          padding: const EdgeInsets.only(
                              left: 4.0), // change it here
                          child: Center(
                            child: Text(
                              widget.hintText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Color(0xff00DC00)),
                            ),
                          ),
                        ),
                ),
              ),
              Container(
                //flex: 1,
                child: Icon(
                  Icons.arrow_drop_down,
                  color:
                      widget.appModel.darkTheme ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Offset getOffset() {
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    double y = renderBox!.localToGlobal(Offset.zero).dy;
    double spaceAvailable = _getAvailableSpace(y + renderBox.size.height);
    if (spaceAvailable > widget.maxListHeight) {
      _isReverse = false;
      return Offset(0, renderBox.size.height);
    } else {
      _isReverse = true;
      return Offset(
          0,
          renderBox.size.height -
              (widget.maxListHeight + renderBox.size.height));
    }
  }



  double _getAvailableSpace(double offsetY) {
    double safePaddingTop = MediaQuery.of(context).padding.top;
    double safePaddingBottom = MediaQuery.of(context).padding.bottom;

    double screenHeight =
        MediaQuery.of(context).size.height - safePaddingBottom - safePaddingTop;

    return screenHeight - offsetY;
  }


  Decoration? _getDecoration() {
    if (_isOpen && !_isReverse) {
      return BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(widget.borderRadius),
              topRight: Radius.circular(
                widget.borderRadius,
              )));
    } else if (_isOpen && _isReverse) {
      return BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(widget.borderRadius),
              bottomRight: Radius.circular(
                widget.borderRadius,
              )));
    } else if (!_isOpen) {
      return BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)));
    }
  }





}