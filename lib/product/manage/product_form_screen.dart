import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/product/product.dart';
import 'package:shop/product/product_provider.dart';

const initForm = true;
final initProduct = ProductFeilds(
  id: 'm5',
  title: 'Tommey Hilfiger Shoes',
  description: 'Tommey shoes for kids summer 2018',
  price: 12.99,
  imageUrl:
      'https://i.pinimg.com/474x/70/db/83/70db8390fe2802994e10492cd8368885.jpg',
);

// keep be sync with Product
class ProductFeilds {
  String? id;
  String? title;
  String? description;
  double? price;
  String? imageUrl;
  bool isFavorite;

  ProductFeilds({
    this.id,
    this.title,
    this.price,
    this.description,
    this.imageUrl,
    this.isFavorite = false,
  });

  void initValues(Product product) {
    id = product.id;
    title = product.title;
    description = product.description;
    price = product.price;
    imageUrl = product.imageUrl;
    isFavorite = product.isFavorite;
  }

  @override
  String toString() {
    return 'ProductFields: id: ${id ?? '_'}, title: $title, price: $price, description: $description, imageUrl: $imageUrl';
  }
}

class ProductFormScreen extends StatefulWidget {
  static const routeName = '/product-form-screen';
  const ProductFormScreen({Key? key}) : super(key: key);

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageURLCotroller = TextEditingController();
  final _imageURLFocusNode = FocusNode();
  final _form = GlobalKey<FormState>();
  var _productFeilds = ProductFeilds();
  String? _editingProductId;
  bool didRunDidchange = false;
  var _isLoading = false;

  void initializeForm() {
    _productFeilds = initProduct;
    _imageURLCotroller.text = initProduct.imageUrl!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (didRunDidchange) {
      return;
    }

    ModalRoute? route = ModalRoute.of(context);
    if (route == null) {
      print('WARN: at didChangeDependencies() route is null');
      return;
    }

    Object? routeArguments = route.settings.arguments;
    if (routeArguments == null) {
      print('NOTE: at didChangeDependencies() routeArguments is null');
      return;
    }

    _editingProductId = routeArguments as String;
    if (_editingProductId != null) {
      var product = Provider.of<ProductProvider>(context, listen: false)
          .getById(_editingProductId!);
      _productFeilds.initValues(product);
      _imageURLCotroller.text = _productFeilds.imageUrl ?? '';
    }

    didRunDidchange = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit & Create Product'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                autovalidate: true,
                key: _form,
                child: ListView(
                  children: [
                    _buildTitle(context),
                    _buildPrice(context),
                    _buildDescription(context),
                    _buildImageUrl(context),
                    _buildImagePreview(context),
                    SizedBox(height: 20),
                    _buildSaveButton(context),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _showErrorDialog(
      BuildContext context, String title, String content, Object e) async {
    await showDialog<Null>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text('$content \nerror: ${e.toString()}'),
        actions: [
          FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              })
        ],
      ),
    );
  }

  @override
  void dispose() {
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageURLCotroller.dispose();
    _imageURLFocusNode.removeListener(_updateImageUrl);
    _imageURLFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_form.currentState != null) {
      final isValid = _form.currentState!.validate();
      if (!isValid) {
        print('Feilds are not valid; save not happende');
        return;
      }
      _form.currentState!.save(); // run onSaved method

      // add product to ProductProvider
      // mod: new product creation
      if (_editingProductId == null) {
        startLoading();
        try {
          final response =
              await Provider.of<ProductProvider>(context, listen: false)
                  .addProduct(Product(
                      id: DateTime.now().toString(),
                      title: _productFeilds
                          .title!, // we validate before to not be null
                      description: _productFeilds.description!,
                      price: _productFeilds.price!,
                      imageUrl: _productFeilds.imageUrl!,
                      isFavorite: _productFeilds.isFavorite));

          endLoading();
          Navigator.of(context).pop();
        } catch (e) {
          endLoading();
          _showErrorDialog(
            context,
            'Error while addProduct',
            'source: ProductFormScreen.dart <PFS_L>',
            e,
          );
          // await showDialog<Null>(
          //   context: context,
          //   builder: (ctx) => AlertDialog(
          //     title: Text('Error while addProduct'),
          //     content: Text(
          //         'source: ProductFormScreen.dart <PFS_L> Error: ${e.toString()}'),
          //     actions: [
          //       FlatButton(
          //           child: Text('OK'),
          //           onPressed: () {
          //             Navigator.of(context).pop();
          //           })
          //     ],
          //   ),
          // );
        }
      }
      // mod: updating product
      if (_editingProductId != null) {
        startLoading();
        try {
          await Provider.of<ProductProvider>(context, listen: false)
              .updateProduct(
            _editingProductId!,
            Product(
              id: _editingProductId!,
              title: _productFeilds.title!, // we validate before to not be null
              description: _productFeilds.description!,
              price: _productFeilds.price!,
              imageUrl: _productFeilds.imageUrl!,
              isFavorite: _productFeilds.isFavorite,
            ),
          );
          endLoading();
          Navigator.of(context).pop();
        } catch (e) {
          endLoading();
          _showErrorDialog(
            context,
            'Error while updateProduct',
            'source: _saveForm()',
            e,
          );
        }
      }

      // return back
    } else {
      print('_saveForm: Error; _form.currentState is null; save not happend');
    }
  }

  Widget _buildTitle(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Title'),
      textInputAction: TextInputAction.next,
      initialValue: _productFeilds.title,
      onFieldSubmitted: (value) {
        FocusScope.of(context).requestFocus(_priceFocusNode);
      },
      validator: (titleField) {
        if (titleField == null || titleField.isEmpty) {
          return 'Title should not be empty';
        }
        return null;
      },
      onSaved: (titleField) {
        // print('titleField.onSaved: titleField: $titleField');
        _productFeilds.title = titleField;
      },
    );
  }

  Widget _buildPrice(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Price'),
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.number,
      initialValue:
          (_productFeilds.price != null) ? _productFeilds.price.toString() : '',
      focusNode: _priceFocusNode,
      onFieldSubmitted: (valur) {
        FocusScope.of(context).requestFocus(_descriptionFocusNode);
      },
      validator: (price) {
        if (price == null || price.isEmpty) {
          return 'Price should not be empty';
        }
        var num = double.tryParse(price);
        if (num == null) {
          return 'Price should be valid number';
        }
        if (num < 0) {
          return 'Price should be greater than Zero';
        }
        return null;
      },
      onSaved: (price) {
        // print('title-field.onSaved: price: $price');
        _productFeilds.price = double.parse(price ??
            '0'); // because we validate price at validator it shouldn't be empty
      },
    );
  }

  Widget _buildDescription(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Description'),
      keyboardType: TextInputType.multiline,
      maxLines: 2,
      initialValue: _productFeilds.description,
      focusNode: _descriptionFocusNode,
      validator: (descriptionField) {
        if (descriptionField == null || descriptionField.isEmpty) {
          return 'Description should not be empty';
        }
        return null;
      },
      onSaved: (descriptionField) {
        // print('title-field.onSaved: descriptionField: $descriptionField');
        _productFeilds.description = descriptionField;
      },
    );
  }

  @override
  void initState() {
    // listen to imageUrl events and act to that by method _updateImageUrl()
    _imageURLFocusNode.addListener(_updateImageUrl);
    initializeForm();
    super.initState();
  }

  void _updateImageUrl() {
    // use this method in intiState()
    // update if 1)remove focus 2)done
    if (_imageURLFocusNode.hasFocus) {
      // we setState when dont have focus
      return;
    }
    if (validateUrl(_imageURLCotroller.text) != null) {
      return;
    }
    setState(() {});
  }

  String? validateUrl(String? urlField) {
    if (urlField == null || urlField.isEmpty) {
      return 'URL should not be empty';
    }
    if (!urlField.startsWith('https://') && !urlField.startsWith('http://')) {
      return 'URL should start with http:// or https://';
    }
    if (!urlField.endsWith('.jpg') &&
        !urlField.endsWith('.jpeg') &&
        !urlField.endsWith('.png')) {
      return 'URL should have format jpg, jpeg or png';
    }
    return null;
  }

  Widget _buildImageUrl(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Image Url'),
      // keyboardType: TextInputType.url,
      keyboardType: TextInputType.multiline,
      maxLines: 3,
      textInputAction: TextInputAction.done,
      controller:
          _imageURLCotroller, // we listen to _imageURLCotroller at intitState
      focusNode: _imageURLFocusNode,
      // onFieldSubmitted: (value) { _saveForm();},
      validator: (url) => validateUrl(url),
      onSaved: (url) {
        // print('title-field.onSaved: url: $url');
        _productFeilds.imageUrl = url;
      },
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      child: Card(
        elevation: 6,
        margin: EdgeInsets.only(top: 8, right: 10),
        // child: _imageURLCotroller.text.isEmpty
        child: validateUrl(_imageURLCotroller.text) != null
            ? Center(
                child: Text(
                'Enter valid image Url',
                style: TextStyle(
                  fontSize: 22,
                ),
              ))
            : FittedBox(
                child: Image.network(
                  _imageURLCotroller.text,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return FlatButton(
      onPressed: _saveForm,
      child: Text(
        'SAVE',
        textAlign: TextAlign.end,
        style: TextStyle(
          fontSize: 22,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void startLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void endLoading() {
    setState(() {
      _isLoading = false;
    });
  }
}
