import 'package:chuck_interceptor/core/chuck_core.dart';
import 'package:chuck_interceptor/helper/chuck_save_helper.dart';
import 'package:chuck_interceptor/model/chuck_http_call.dart';
import 'package:chuck_interceptor/ui/widget/chuck_call_response_preview_widget.dart';
import 'package:chuck_interceptor/ui/widget/chuck_call_response_widget.dart';
import 'package:chuck_interceptor/utils/chuck_constants.dart';
import 'package:chuck_interceptor/ui/widget/chuck_call_error_widget.dart';
import 'package:chuck_interceptor/ui/widget/chuck_call_overview_widget.dart';
import 'package:chuck_interceptor/ui/widget/chuck_call_request_widget.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ChuckCallDetailsScreen extends StatefulWidget {
  final ChuckHttpCall call;
  final ChuckCore core;

  const ChuckCallDetailsScreen(this.call, this.core);

  @override
  _ChuckCallDetailsScreenState createState() => _ChuckCallDetailsScreenState();
}

class _ChuckCallDetailsScreenState extends State<ChuckCallDetailsScreen> with SingleTickerProviderStateMixin {
  ChuckHttpCall get call => widget.call;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.core.directionality ?? Directionality.of(context),
      child: Theme(
        data: ThemeData(brightness: widget.core.brightness),
        child: StreamBuilder<List<ChuckHttpCall>>(
          stream: widget.core.callsSubject,
          initialData: [widget.call],
          builder: (context, callsSnapshot) {
            if (callsSnapshot.hasData) {
              final ChuckHttpCall? call =
                  callsSnapshot.data!.firstWhere((snapshotCall) => snapshotCall.id == widget.call.id);
              if (call != null) {
                return _buildMainWidget();
              } else {
                return _buildErrorWidget();
              }
            } else {
              return _buildErrorWidget();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMainWidget() {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: ChuckConstants.lightRed,
          foregroundColor: Colors.white,
          key: const Key('share_key'),
          onPressed: () async {
            Share.share(
              await _getSharableResponseString(),
              subject: 'Request Details',
            );
          },
          child: const Icon(Icons.share),
        ),
        appBar: AppBar(
          centerTitle: false,
          bottom: TabBar(
            indicatorColor: ChuckConstants.lightRed,
            tabs: const [
              const Tab(icon: Icon(Icons.info_outline), text: "Overview"),
              const Tab(icon: Icon(Icons.arrow_upward), text: "Request"),
              const Tab(icon: Icon(Icons.arrow_downward), text: "Response"),
              const Tab(icon: Icon(Icons.preview), text: "Preview"),
              const Tab(icon: Icon(Icons.warning), text: "Error"),
            ],
          ),
          title: Column(
            children: [
              // const Text('Chuck - HTTP Call Details', style: TextStyle(fontSize: 16)),
              // SizedBox(height: 6),
              Text(
                '${widget.call.method}:   ${widget.call.endpoint}${widget.call.response?.status != 0 && widget.call.response?.status != -1 ? ': ${widget.call.response?.status ?? ''}' : ''}',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _getEndpointTextColor(context),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ChuckCallOverviewWidget(widget.call),
            ChuckCallRequestWidget(widget.call),
            ChuckCallResponseWidget(widget.call),
            ChuckCallResponsePreviewWidget(call),
            ChuckCallErrorWidget(widget.call),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return const Center(child: Text("Failed to load data"));
  }

  Future<String> _getSharableResponseString() async {
    return ChuckSaveHelper.buildCallLog(widget.call);
  }

  Color? _getEndpointTextColor(BuildContext context) {
    if (call.loading) {
      return ChuckConstants.grey;
    } else {
      return _getStatusTextColor(context);
    }
  }

  Color? _getStatusTextColor(BuildContext context) {
    final int? status = call.response!.status;
    if (status == -1) {
      return ChuckConstants.red;
    } else if (status! < 200) {
      return Theme.of(context).textTheme.bodyLarge!.color;
    } else if (status >= 200 && status < 300) {
      return ChuckConstants.green;
    } else if (status >= 300 && status < 400) {
      return ChuckConstants.orange;
    } else if (status >= 400 && status < 600) {
      return ChuckConstants.red;
    } else {
      return Theme.of(context).textTheme.bodyLarge!.color;
    }
  }
}
