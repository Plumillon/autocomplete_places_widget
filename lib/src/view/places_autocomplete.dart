import 'dart:async';
import 'dart:developer';

import 'package:autocomplete_places_widget/src/helpers/debouncer.dart';
import 'package:autocomplete_places_widget/src/models/prediction.dart';
import 'package:autocomplete_places_widget/src/providers/google_places_provider.dart';
import 'package:autocomplete_places_widget/src/providers/mapbox_places_provider.dart';
import 'package:autocomplete_places_widget/src/providers/places_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget that uses the Google Places API to provide places suggestions.
/// The user can select an option from the suggestions, and the selected
/// option will be passed to the [onOptionSelected] callback.
/// The options menu can be customized using the [menuBuilder] and
/// [menuOptionBuilder] parameters.
class PlacesAutoComplete extends StatefulWidget {
  /// The places provider to use.
  /// Depending on the passed [PlacesProviderConfig] type, the provider will be different.
  /// [GooglePlacesProviderConfig]: Google Places API [https://developers.google.com/maps/documentation/places/web-service/overview]
  /// [MapboxPlacesProviderConfig]: MapBox Places API [https://docs.mapbox.com/api/search/search-box/]
  late final PlacesProvider provider;

  /// A callback that is called when the user selects an option.
  final void Function(Prediction)? onOptionSelected;

  /// A builder for the text field used to input search queries.
  /// If not provided, a default text field will be used.
  ///
  /// Ensure using the provided [TextEditingController], [FocusNode] and [onFieldSubmitted] callback
  /// to make the widget work properly. Check the package example for more details.
  ///
  /// Note: You should not use your own TextEditingController and FocusNode with the [textFormFieldBuilder], instead you can use
  /// the provided TextEditingController and FocusNode provided in [PlacesAutoComplete] widget.
  final Widget Function(
          BuildContext, TextEditingController, FocusNode, void Function())?
      textFormFieldBuilder;

  /// A builder for the options view.
  final Widget Function(
      BuildContext context,
      AutocompleteOnSelected<Prediction> onSelected,
      Iterable<Prediction> options)? menuBuilder;

  /// A builder for a single option view in the menu.
  final Widget Function(BuildContext context, int index, Prediction prediction)?
      menuOptionBuilder;

  /// The controller for the text field.
  /// If this parameter is not null, then [focusNode] must also be not null.
  final TextEditingController? textEditingController;

  /// The focus node for the text field.
  /// If this parameter is not null, then [textEditingController] must also be
  /// not null.
  final FocusNode? focusNode;

  /// The time (in milliseconds) to wait after the user stops typing
  /// to make the API request.
  final int debounceTime;

  /// If true, the predictions will include the latitude and longitude of the
  /// place (an additional API request will be made to get the lat/lng).
  final bool includeLatLng;

  /// The maximum height of the options menu.
  final double optionsMaxHeight;

  /// The maximum width of the options menu.
  final double? optionsMaxWidth;

  /// The color of the menu.
  final Color? menuColor;

  /// The elevation of the menu.
  final double menuElevation;

  /// The shape of the menu.
  final double menuBorderRadius;

  /// If true, the menu option will be dense.
  final bool denseMenuOption;

  /// If true, the predictions history will be saved in shared preferences
  /// and will be displayed in the options menu when the current query is empty
  final bool enableHistory;

  /// if True, The prediction saved will contain only the `placeId`, `description` and `LatLng` (if available)
  final bool liteModeHistory;

  /// A callback that is called when the widget is searching for options.
  /// This can be used to show a loading indicator.
  ///
  /// Example:
  /// ```dart
  /// loadingCallback: (bool loading) {
  ///  if (loading) {
  ///   setState(() {
  ///   _yourLoadingVariable = true;
  ///  });
  /// } else {
  ///  setState(() {
  ///  _yourLoadingVariable = false;
  /// });
  /// }
  final void Function(bool loading)? loadingCallback;

  /// A callback that is called when an API exception occurs.
  /// This can be used to show an error message.
  ///
  /// Example:
  /// ```dart
  /// apiExceptionCallback: (bool apiException) {
  ///  if (apiException) {
  ///   setState(() {
  ///  _yourErrorMsgVariable = "An error occurred while searching for places".
  ///  });
  /// } else {
  ///  setState(() {
  /// _yourErrorMsgVariable = null;
  /// });
  /// }
  final void Function(Object apiExceptionCallback)? apiExceptionCallback;

  /// Creates a new Google Places Autocomplete widget.
  /// The [apiKey] parameter is required if [proxyURL] is null.
  PlacesAutoComplete({
    super.key,
    required PlacesProviderConfig providerConfig,
    this.onOptionSelected,
    this.menuOptionBuilder,
    this.textEditingController,
    this.focusNode,
    this.debounceTime = 500,
    this.includeLatLng = false,
    this.optionsMaxHeight = 275,
    this.optionsMaxWidth,
    this.textFormFieldBuilder,
    this.menuBuilder,
    this.enableHistory = false,
    this.liteModeHistory = false,
    this.denseMenuOption = true,
    this.menuColor,
    this.menuElevation = 2.0,
    this.menuBorderRadius = 8.0,
    this.loadingCallback,
    this.apiExceptionCallback,
  })  : assert((focusNode == null) == (textEditingController == null),
            'textEditingController and focusNode must be provided together'),
        assert(
          providerConfig is GooglePlacesProviderConfig ||
              providerConfig is MapboxPlacesProviderConfig,
          'Invalid provider config',
        ) {
    switch (providerConfig.runtimeType) {
      case GooglePlacesProviderConfig:
        provider = GooglePlacesProvider(
            config: providerConfig as GooglePlacesProviderConfig);
        break;
      case MapboxPlacesProviderConfig:
        provider = MapboxPlacesProvider(
            config: providerConfig as MapboxPlacesProviderConfig);
        break;
    }
  }

  @override
  State<PlacesAutoComplete> createState() => _PlacesAutoCompleteState();
}

class _PlacesAutoCompleteState extends State<PlacesAutoComplete> {
  // The query currently being searched for. If null, there is no pending
  // request.
  String? _currentQuery;

  // The most recent options received from the API.
  late Iterable<Prediction> _lastPredictions = <Prediction>[];

  late final Debounceable<Iterable<Prediction>?, String> _debouncedSearch;

  // Calls the "remote" API to search with the given query. Returns null when
  // the call has been made obsolete.
  Future<Iterable<Prediction>?> _search(String query) async {
    if (query.isEmpty) {
      return _predictionsHistory;
    }

    // if (_lastPredictions.contains(Prediction(name: query))) {
    //   return _lastPredictions;
    // }
    // if (_predictionsHistory.contains(Prediction(name: query))) {
    //   return _predictionsHistory;
    // }

    _currentQuery = query;

    late final Iterable<Prediction> predictions;

    predictions = await _insertPredictions(_currentQuery!);

    // If another search happened after this one, throw away these options.
    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;

    return predictions;
  }

  List<Prediction> _predictionsHistory = [];

  Future<void> getPredictionsHistory() async {
    if (!widget.enableHistory) {
      return;
    }
    _predictionsHistory =
        await widget.provider.getPredictionsFromSharedPref() ?? [];
    log("predictionsHistory: $_predictionsHistory");
  }

  void addPredictionToHistoryCallBack(Prediction prediction) {
    if (!widget.enableHistory) {
      return;
    }
    if (_predictionsHistory.contains(prediction)) {
      log("prediction already in history: $prediction");
      return;
    }
    // max 5 predictions
    if (_predictionsHistory.length >= 5) {
      _predictionsHistory.removeAt(0);
    }
    _predictionsHistory.add(prediction);
    log("prediction added to history: $prediction");
    widget.provider
        .savePrediction(prediction, liteMode: widget.liteModeHistory);
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = debounce<Iterable<Prediction>?, String>(_search,
        debounceDuration: Duration(milliseconds: widget.debounceTime));
    getPredictionsHistory();
  }

  static String _displayStringForPrediction(Prediction prediction) =>
      prediction.name ?? '';

  @override
  Widget build(BuildContext context) {
    double defaultFieldAndMenuWidth = MediaQuery.sizeOf(context).width * 0.9;
    return RawAutocomplete<Prediction>(
      textEditingController: widget.textEditingController,
      focusNode: widget.focusNode,
      displayStringForOption: _displayStringForPrediction,
      fieldViewBuilder: (BuildContext context, TextEditingController controller,
          FocusNode focusNode, VoidCallback onFieldSubmitted) {
        return SizedBox(
          width: widget.optionsMaxWidth ?? defaultFieldAndMenuWidth,
          child: widget.textFormFieldBuilder != null
              ? widget.textFormFieldBuilder!
                  .call(context, controller, focusNode, onFieldSubmitted)
              : TextFormField(
                  decoration: _defaultInputDecoration(),
                  controller: controller,
                  focusNode: focusNode,
                  onFieldSubmitted: (_) {
                    onFieldSubmitted();
                  },
                ),
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final Iterable<Prediction>? options =
            await _debouncedSearch(textEditingValue.text);
        if (options == null) {
          return _lastPredictions;
        }
        _lastPredictions = options;
        return options;
      },
      optionsViewBuilder: (context, onSelected, options) {
        if (widget.menuBuilder != null) {
          return widget.menuBuilder!.call(context, onSelected, options);
        }
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: widget.menuElevation,
            color: widget.menuColor,
            borderRadius: BorderRadius.circular(widget.menuBorderRadius),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: widget.optionsMaxHeight,
                  maxWidth: widget.optionsMaxWidth ?? defaultFieldAndMenuWidth),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final Prediction prediction = options.elementAt(index);

                  return InkWell(
                    child: Builder(builder: (context) {
                      final bool highlight =
                          AutocompleteHighlightedOption.of(context) == index;
                      if (highlight) {
                        SchedulerBinding.instance.addPostFrameCallback(
                            (Duration timeStamp) {
                          Scrollable.ensureVisible(context, alignment: 0.5);
                        }, debugLabel: 'AutocompleteOptions.ensureVisible');
                      }
                      return widget.menuOptionBuilder
                              ?.call(context, index, prediction) ??
                          ListTile(
                            onTap: () async {
                              onSelected(prediction);
                              if (widget.includeLatLng) {
                                await widget.provider
                                    .getPlaceDetailsFromPlaceId(
                                  prediction,
                                );
                              }
                              widget.onOptionSelected?.call(prediction);
                              addPredictionToHistoryCallBack(prediction);
                            },
                            tileColor:
                                highlight ? Theme.of(context).focusColor : null,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                              top: Radius.circular(
                                  index == 0 ? widget.menuBorderRadius : 0.0),
                              bottom: Radius.circular(
                                  index == options.length - 1
                                      ? widget.menuBorderRadius
                                      : 0.0),
                            )),
                            dense: widget.denseMenuOption,
                            title: Text(_displayStringForPrediction(
                                options.elementAt(index))),
                          );
                    }),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Iterable<Prediction>> _insertPredictions(String query) async {
    if (query == '') {
      return const Iterable<Prediction>.empty();
    }
    try {
      widget.loadingCallback?.call(true);

      return await widget.provider.fetchPlaces(query);
    } catch (e) {
      widget.apiExceptionCallback?.call(e);

      return [];
    } finally {
      widget.loadingCallback?.call(false);
    }
  }

  InputDecoration _defaultInputDecoration() {
    return InputDecoration(
      hintText: 'e.g. Paris, France',
      labelText: 'Search for a place',
      prefixIcon: const Icon(Icons.search),
      errorMaxLines: 2,
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );
  }
}
