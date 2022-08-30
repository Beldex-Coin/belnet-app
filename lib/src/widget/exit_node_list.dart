import 'package:flutter/material.dart';

class CustDropDown<T> extends StatefulWidget {
  final List<CustDropdownMenuItem> items;
  final Function onChanged;
  final String hintText;
  final double borderRadius;
  final double maxListHeight;
  final double borderWidth;
  final int defaultSelectedIndex;
  final bool enabled;

  const CustDropDown(
      {required this.items,
        required this.onChanged,
        this.hintText = "",
        this.borderRadius = 0,
        this.borderWidth = 1,
        this.maxListHeight = 100,
        this.defaultSelectedIndex = -1,
        Key? key,
        this.enabled = true})
      : super(key: key);

  @override
  _CustDropDownState createState() => _CustDropDownState();
}

class _CustDropDownState extends State<CustDropDown>
    with WidgetsBindingObserver {
  bool _isOpen = false, _isAnyItemSelected = false, _isReverse = false;
  late OverlayEntry _overlayEntry;
  late RenderBox? _renderBox;
  Widget? _itemSelected;
  late Offset dropDownOffset;
  final LayerLink _layerLink = LayerLink();

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
    Overlay.of(context)!.insert(_overlayEntry);
  }

  void _removeOverlay() {
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
      _overlayEntry.remove();
    }
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    _renderBox = context.findRenderObject() as RenderBox?;

    var size = _renderBox!.size;

    dropDownOffset = getOffset();

    return OverlayEntry(
        maintainState: false,
        builder: (context) => Align(
          alignment: Alignment.center,
          child: CompositedTransformFollower(
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
                      padding: EdgeInsets.only(top:MediaQuery.of(context).size.height*0.06/3),
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
                          //color:
                          elevation: 0,
                          shadowColor: Colors.grey,
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: widget.items
                                .map((item) => GestureDetector(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: item.child,
                              ),
                              onTap: () {
                                if (mounted) {
                                  setState(() {
                                    _isAnyItemSelected = true;
                                    _itemSelected = item.child;
                                    _removeOverlay();
                                    if (widget.onChanged != null)
                                      widget.onChanged(item.value);
                                  });
                                }
                              },
                            ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                 // ),
                ],
              ),
            ),
          ),
        ));
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                flex: 3,
                child: _isAnyItemSelected
                    ? Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: _itemSelected!,
                )
                    : Padding(
                  padding:
                  const EdgeInsets.only(left: 4.0), // change it here
                  child: Center(
                    child: Text(
                      widget.hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color:Color(0xff00DC00)),
                    ),
                  ),
                ),
              ),
              const Flexible(
                flex: 1,
                child: Icon(
                  Icons.arrow_drop_down,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class CustDropdownMenuItem<T> extends StatelessWidget {
  final String value;
  final Widget child;

  const CustDropdownMenuItem({required this.value, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

















