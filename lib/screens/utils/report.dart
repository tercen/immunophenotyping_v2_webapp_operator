import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pd;

class ReportTitle{
  final String title;
  final pd.PdfFont font;

  ReportTitle(this.title, this.font);
}

class ReportRow{
  final List<dynamic> _rowElements = [];
  final List<double> _widths = [];

  double _height = 0;
  double _width = 0;

  void addElement(dynamic el, Size sz){
    _rowElements.add(el);

    if( sz.height > _height ){
      _height = sz.height + 25;
    }

    // _width += 20;
    _width += sz.width + 20;
    _widths.add(sz.width);
  }

  pd.PdfPage addRowToPage(pd.PdfPage page, double offsetT, {bool centerSingle = true}){
    ReportFont repFont = ReportFont();
    double offX = 0;

    if( _rowElements.length == 1 && centerSingle ){
      offX = page.size.width/2 - _widths.first/2;
    }

    for( var i = 0; i < _rowElements.length; i++){
      var el = _rowElements[i];
      if( el is String ){
        page.graphics.drawString(el, repFont.font, bounds: Rect.fromLTRB(offX, offsetT, 0, 0) );
        
      }

      if( el is ReportTitle ){
        page.graphics.drawString(el.title, el.font, bounds: Rect.fromLTRB(offX, offsetT, 0, 0) );
        offsetT += 25;
        
      }

      if( el is pd.PdfBitmap){
        page.graphics.drawImage(el, Rect.fromLTWH(offX, offsetT,  (el.width as double), (el.height as double)));
      }

      if( el is TitledBitmap ){
        double offT = 0;
        
        for( var i = 0; i < el.titles.length; i++  ){
          var title = el.titles[i];
          var brushColor = el.colors[i];
          page.graphics.drawString(title, repFont.getFont(size: 48), 
                bounds: Rect.fromLTRB(offX + el.img.width/2 - (el.getTitleWidth(i)/2), offsetT + offT, 0, 0),
                brush: pd.PdfSolidBrush(brushColor) );
          offT += 64;
        }
        
        page.graphics.drawImage(el.img, Rect.fromLTWH(offX, offsetT+offT,  (el.img.width as double), (el.img.height as double)));

      }

      offX += 20 + _widths[i];
    }


    return page;
  }

  Size getSize(){
    return Size(_width, _height);
  }
}

class ReportFont {
  static final ReportFont _singleton = ReportFont._internal();
  late Uint8List fontData;
  late pd.PdfFont font;
  late pd.PdfFont fontLarge;
  
  factory ReportFont() {
    return _singleton;
  }
  
  ReportFont._internal();

  Future<void> init() async{
    fontData =  (await rootBundle.load("fonts/RobotoMono-Regular.ttf")).buffer.asUint8List();
    font = pd.PdfTrueTypeFont(fontData, 12);
    fontLarge = pd.PdfTrueTypeFont(fontData, 48, style: pd.PdfFontStyle.bold);
   
  }

  pd.PdfFont getFont({double? size}){
    if( size == null ){
    return font;
    }else{
      return pd.PdfTrueTypeFont(fontData, size);
    }
  }
}

class Report{
  final List<ReportRow> _rows = [];

  double _height = 0;
  double _width = 0;

  void addRow(ReportRow row){
    _rows.add(row);

    var rowSz = row.getSize();
    _height += 50 + rowSz.height;

    if( rowSz.width > _width ){
      _width = rowSz.width;
    }
  }

  pd.PdfDocument columnToPage( pd.PdfDocument pdfDoc, {pd.PdfBitmap? logo } ){
    
    double totalHeight = 0;
    double totalWidth = 0;
    for( var row in _rows ){
      totalHeight += row.getSize().height;
      totalWidth = row.getSize().width > totalWidth ? row.getSize().width  : totalWidth;
    }
    totalWidth += pdfDoc.pageSettings.margins.left + pdfDoc.pageSettings.margins.right + 50;


    if( logo != null ){
      totalHeight += 150;
    }

    print("Column to page $totalWidth x $totalHeight");

    pdfDoc.pageSettings.margins.bottom = 10;
    pdfDoc.pageSettings.size =  Size(totalHeight, totalWidth);
    if( _height > _width){
      pdfDoc.pageSettings.orientation = pd.PdfPageOrientation.portrait;
    }else{
      pdfDoc.pageSettings.orientation = pd.PdfPageOrientation.landscape;
    }
    
    var page = pdfDoc.pages.add();
    double offsetT = 0;
    for( var row in _rows ){
      page = row.addRowToPage(page, offsetT);
      offsetT += row.getSize().height;
    }      



    if( logo != null ){
      double newHeight = 50;
      double newWidth = (newHeight/(logo.height as double)) * (logo.width as double);
      page.graphics.drawImage(logo, Rect.fromLTWH(totalWidth-300, totalHeight-100,  newWidth, newHeight));
    }
      

    return pdfDoc;
  }
}

class TitledBitmap{
  final List<String> titles;
  final List<pd.PdfColor> colors = [];
  final pd.PdfBitmap img;

  TitledBitmap( this.titles, this.img, {List<pd.PdfColor>? titleColors}){
    if( titleColors != null ){
      assert( titles.length == titleColors.length );
      for( var t in titleColors ){
        colors.add(t);
      }
    }else{
      for( var _ in titles ){
        colors.add(pd.PdfColor(0, 0, 0));
      }
    }
  }

  double getHeight(){
    double height = img.height as double;
    ReportFont repFont = ReportFont();
    for( var t in titles ){
      var strSz = repFont.getFont(size: 48).measureString(t);
      height += 64 + strSz.height;
    }
    
    
    return height; //strSz.height + 50 + img.height;
  }

  double getTitleWidth(int idx){
    ReportFont repFont = ReportFont();
    
    var strSz = repFont.getFont(size: 48).measureString(titles[idx]);
    return strSz.width;
  }
}
