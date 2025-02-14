import 'dart:math';
import 'package:flutter/services.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:my_idena/app_icons.dart';
import 'package:my_idena/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:my_idena/dimens.dart';
import 'package:my_idena/model/address.dart';
import 'package:my_idena/model/db/appdb.dart';
import 'package:my_idena/model/db/contact.dart';
import 'package:my_idena/model/smartContractMultiSig.dart';
import 'package:my_idena/network/model/response/contract/contract_call_response.dart';
import 'package:my_idena/factory/smart_contract_service.dart';
import 'package:my_idena/service_locator.dart';
import 'package:my_idena/styles.dart';
import 'package:my_idena/ui/send/send_sheet.dart';
import 'package:my_idena/ui/util/routes.dart';
import 'package:my_idena/ui/util/ui_util.dart';
import 'package:my_idena/ui/widgets/app_text_field.dart';
import 'package:my_idena/ui/widgets/buttons.dart';
import 'package:my_idena/appstate_container.dart';
import 'package:my_idena/ui/widgets/dialog.dart';
import 'package:my_idena/ui/widgets/sheet_util.dart';
import 'package:my_idena/util/app_ffi/apputil.dart';
import 'package:my_idena/util/caseconverter.dart';
import 'package:my_idena/util/enums/wallet_type.dart';
import 'package:my_idena/util/sharedprefsutil.dart';
import 'package:timelines/timelines.dart';

const kTileHeight = 50.0;
const completeColor = Color(0xff5e6172);
const inProgressColor = Color(0xff5ec792);
const todoColor = Color(0xffd1d2d7);

class MultiSigDetail extends StatefulWidget {
  final SmartContractMultiSig smartContractMultiSig;
  final Contact contact;
  final String addressDestination;
  final String address;

  MultiSigDetail({
    this.smartContractMultiSig,
    this.contact,
    this.addressDestination,
    this.address,
  }) : super();

  _MultiSigDetailStateState createState() => _MultiSigDetailStateState();
}

enum AddressStyle { TEXT60, TEXT90, PRIMARY }

class _MultiSigDetailStateState extends State<MultiSigDetail> {
  int _processIndex;
  var _processes;

  FocusNode _blockAddressFocusNode;
  TextEditingController _blockAddressController;

  AddressStyle _blockAddressStyle;
  String _addressHint = "";
  String _addressValidationText = "";
  List<Contact> _contacts;

// Used to replace address textfield with colorized TextSpan
  bool _addressValidAndUnfocused = false;
  // Set to true when a contact is being entered
  bool _isContact = false;
  // Buttons States (Used because we hide the buttons under certain conditions)
  bool _pasteButtonVisible = true;
  bool _showContactButton = true;
  bool validRequest = true;

  Color getColor(int index) {
    if (index == _processIndex && index != 4) {
      return inProgressColor;
    } else if (index <= _processIndex) {
      return completeColor;
    } else {
      return todoColor;
    }
  }

  @override
  void initState() {
    super.initState();

    _processes = ['Deploy', 'Lock', 'Voters ok', 'Push', 'Terminate'];

    _blockAddressFocusNode = FocusNode();
    _blockAddressController = TextEditingController();
    _blockAddressStyle = AddressStyle.TEXT60;
    _contacts = List();
    if (widget.contact != null) {
      // Setup initial state for contact pre-filled
      _blockAddressController.text = widget.contact.name;
      _isContact = true;
      _showContactButton = false;
      _pasteButtonVisible = false;
      _blockAddressStyle = AddressStyle.PRIMARY;
    } else if (widget.addressDestination != null) {
      // Setup initial state with prefilled address
      _blockAddressController.text = widget.addressDestination;
      _showContactButton = false;
      _pasteButtonVisible = false;
      _blockAddressStyle = AddressStyle.TEXT90;
      _addressValidAndUnfocused = true;
    }

// On address focus change
    _blockAddressFocusNode.addListener(() {
      if (_blockAddressFocusNode.hasFocus) {
        setState(() {
          _addressHint = null;
          //_addressValidAndUnfocused = false;
        });
        _blockAddressController.selection = TextSelection.fromPosition(
            TextPosition(offset: _blockAddressController.text.length));
        if (_blockAddressController.text.startsWith("@")) {
          sl
              .get<DBHelper>()
              .getContactsWithNameLike(_blockAddressController.text)
              .then((contactList) {
            setState(() {
              _contacts = contactList;
            });
          });
        }
      } else {
        setState(() {
          _addressHint = "";
          _contacts = [];
          if (Address(_blockAddressController.text).isValid()) {
            //_addressValidAndUnfocused = true;
          }
        });
        if (_blockAddressController.text.trim() == "@") {
          _blockAddressController.text = "";
          setState(() {
            _showContactButton = true;
          });
        }
      }
    });

    if (widget.smartContractMultiSig.getLastBalanceUpdates().txReceipt.method ==
        "terminate") {
      _processIndex = 4;
    } else {
      if (widget.smartContractMultiSig
              .getLastBalanceUpdates()
              .txReceipt
              .method ==
          "push") {
        _processIndex = 3;
      } else {
        if (widget.smartContractMultiSig.state == 2) {
          _processIndex = 2;
        } else {
          _processIndex = 1;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        minimum:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.035),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                //Empty SizedBox
                SizedBox(
                  width: 60,
                  height: 60,
                ),
                Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      height: 5,
                      width: MediaQuery.of(context).size.width * 0.15,
                      decoration: BoxDecoration(
                        color: StateContainer.of(context).curTheme.text10,
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                    ),
                  ],
                ),
                //Empty SizedBox
                SizedBox(
                  width: 60,
                  height: 60,
                ),
              ],
            ),
            Container(
              height: 60,
              child: Timeline.tileBuilder(
                theme: TimelineThemeData(
                  direction: Axis.horizontal,
                  connectorTheme: ConnectorThemeData(
                    space: 20.0,
                    thickness: 5.0,
                  ),
                ),
                builder: TimelineTileBuilder.connected(
                  connectionDirection: ConnectionDirection.before,
                  itemExtentBuilder: (_, __) =>
                      MediaQuery.of(context).size.width / _processes.length,
                  oppositeContentsBuilder: (context, index) {
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: index == 0
                            ? Icon(FontAwesome5.file_contract,
                                size: 14, color: getColor(index))
                            : index == 1
                                ? Icon(FontAwesome5.lock,
                                    size: 14, color: getColor(index))
                                : index == 2
                                    ? Icon(FontAwesome5.vote_yea,
                                        size: 14, color: getColor(index))
                                    : index == 3
                                        ? Icon(FontAwesome5.share_square,
                                            size: 14, color: getColor(index))
                                        : Icon(FontAwesome.stop_circle,
                                            size: 16, color: getColor(index)));
                  },
                  contentsBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        _processes[index],
                        style: TextStyle(
                          color: getColor(index),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    );
                  },
                  indicatorBuilder: (_, index) {
                    var color;
                    var child;
                    if (index == _processIndex && index != 4) {
                      color = inProgressColor;
                      child = Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: index == 3
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10.0,
                              )
                            : CircularProgressIndicator(
                                strokeWidth: 1.0,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                      );
                    } else if (index <= _processIndex) {
                      color = completeColor;
                      child = Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10.0,
                      );
                    } else {
                      color = todoColor;
                    }

                    if (index <= _processIndex) {
                      return Stack(
                        children: [
                          CustomPaint(
                            size: Size(20.0, 20.0),
                            painter: _BezierPainter(
                              color: color,
                              drawStart: index > 0,
                              drawEnd: index < _processIndex,
                            ),
                          ),
                          DotIndicator(
                            size: 20.0,
                            color: color,
                            child: child,
                          ),
                        ],
                      );
                    } else {
                      return Stack(
                        children: [
                          CustomPaint(
                            size: Size(10.0, 10.0),
                            painter: _BezierPainter(
                              color: color,
                              drawEnd: index < _processes.length - 1,
                            ),
                          ),
                          OutlinedDotIndicator(
                            borderWidth: 4.0,
                            color: color,
                          ),
                        ],
                      );
                    }
                  },
                  connectorBuilder: (_, index, type) {
                    if (index > 0) {
                      if (index == _processIndex) {
                        final prevColor = getColor(index - 1);
                        final color = getColor(index);
                        var gradientColors;
                        if (type == ConnectorType.start) {
                          gradientColors = [
                            Color.lerp(prevColor, color, 0.5),
                            color
                          ];
                        } else {
                          gradientColors = [
                            prevColor,
                            Color.lerp(prevColor, color, 0.5)
                          ];
                        }
                        return DecoratedLineConnector(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                            ),
                          ),
                        );
                      } else {
                        return SolidLineConnector(
                          color: getColor(index),
                        );
                      }
                    } else {
                      return null;
                    }
                  },
                  itemCount: _processes.length,
                ),
              ),
            ),
            Container(
              height: 190,
              margin: EdgeInsetsDirectional.only(start: 10.0, end: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      text: '',
                      children: [
                        TextSpan(
                          text: "Smart Contract : ",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        TextSpan(
                            text: widget.smartContractMultiSig.contractAddress,
                            style:
                                AppStyles.textStyleTransactionAddress(context)),
                      ],
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      text: '',
                      children: [
                        TextSpan(
                          text: "Owner : ",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        TextSpan(
                            text: widget.smartContractMultiSig.owner,
                            style:
                                AppStyles.textStyleTransactionAddress(context)),
                      ],
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      text: '',
                      children: [
                        TextSpan(
                          text: "Balance : ",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        TextSpan(
                          text:
                              widget.smartContractMultiSig.balance.toString() +
                                  " iDNA",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w100,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      text: '',
                      children: [
                        TextSpan(
                          text: "Stake : ",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        TextSpan(
                          text: widget.smartContractMultiSig.stake.toString() +
                              " iDNA",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w100,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      text: '',
                      children: [
                        TextSpan(
                          text: "Number of voters : ",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        TextSpan(
                          text:
                              widget.smartContractMultiSig.maxVotes.toString(),
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w100,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      text: '',
                      children: [
                        TextSpan(
                          text: "Number of votes done : ",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        TextSpan(
                          text: widget.smartContractMultiSig.nbVotesDone
                              .toString(),
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w100,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      text: '',
                      children: [
                        TextSpan(
                          text:
                              "Min nb of votes required to unlock the coins : ",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        TextSpan(
                          text:
                              widget.smartContractMultiSig.minVotes.toString(),
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w100,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      text: '',
                      children: [
                        TextSpan(
                          text: "Status : ",
                          style: TextStyle(
                            color:
                                StateContainer.of(context).curTheme.primary60,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        widget.smartContractMultiSig.state == 1
                            ? TextSpan(
                                text:
                                    "The list of voters is not defined yet (actually " +
                                        widget.smartContractMultiSig.count
                                            .toString() +
                                        " voter(s))",
                                style: TextStyle(
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .primary60,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w100,
                                  fontFamily: 'Roboto',
                                ),
                              )
                            : TextSpan(
                                text: "The list of voters is complete",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w100,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                      ],
                    ),
                  ),
                  widget.smartContractMultiSig.getLastBalanceUpdates() == null
                      ? SizedBox()
                      : RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            text: '',
                            children: [
                              TextSpan(
                                text: "Last status : ",
                                style: TextStyle(
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .primary60,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              widget.smartContractMultiSig
                                          .getLastBalanceUpdates()
                                          .txReceipt ==
                                      null
                                  ? TextSpan(
                                      text: widget.smartContractMultiSig
                                              .getLastBalanceUpdates()
                                              .type +
                                          " - Success",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w100,
                                        fontFamily: 'Roboto',
                                      ),
                                    )
                                  : widget.smartContractMultiSig
                                          .getLastBalanceUpdates()
                                          .txReceipt
                                          .success
                                      ? TextSpan(
                                          text: widget.smartContractMultiSig
                                                  .getLastBalanceUpdates()
                                                  .txReceipt
                                                  .method +
                                              " - Success",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w100,
                                            fontFamily: 'Roboto',
                                          ),
                                        )
                                      : TextSpan(
                                          text: widget.smartContractMultiSig
                                                  .getLastBalanceUpdates()
                                                  .txReceipt
                                                  .method +
                                              " - " +
                                              widget.smartContractMultiSig
                                                  .getLastBalanceUpdates()
                                                  .txReceipt
                                                  .errorMsg,
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w100,
                                            fontFamily: 'Roboto',
                                          ),
                                        ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
            _processIndex == 4
                ? SizedBox()
                : Container(
                    alignment: Alignment.topCenter,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width * 0.105,
                              right: MediaQuery.of(context).size.width * 0.105),
                          alignment: Alignment.bottomCenter,
                          constraints:
                              BoxConstraints(maxHeight: 174, minHeight: 0),
                          // ********************************************* //
                          // ********* The pop-up Contacts List ********* //
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: StateContainer.of(context)
                                    .curTheme
                                    .backgroundDarkest,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                margin: EdgeInsets.only(bottom: 0),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.only(bottom: 0, top: 0),
                                  itemCount: _contacts.length,
                                  itemBuilder: (context, index) {
                                    return _buildContactItem(_contacts[index]);
                                  },
                                ), // ********* The pop-up Contacts List End ********* //
                                // ************************************************** //
                              ),
                            ),
                          ),
                        ),

                        // ******* Enter Address Container ******* //
                        getEnterAddressContainer(),
                        // ******* Enter Address Container End ******* //
                      ],
                    ),
                  ),
            _processIndex == 4
                ? SizedBox()
                : Container(
                    alignment: AlignmentDirectional(0, 0),
                    margin: EdgeInsets.only(top: 3),
                    child: Text(_addressValidationText,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: StateContainer.of(context).curTheme.primary,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                        )),
                  ),
            Expanded(
              child: Center(
                child: Stack(
                  children: <Widget>[
                    Row(
                      children: [],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // PUSH BUTTON
                    _processIndex < 4 &&
                            widget.smartContractMultiSig.nbVotesDone != null &&
                            widget.smartContractMultiSig.minVotes != null &&
                            widget.smartContractMultiSig.nbVotesDone >=
                                widget.smartContractMultiSig.minVotes
                        ? AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context).scPushButton,
                            Dimens.BUTTON_BOTTOM_SMALL_PLACE, onPressed: () {
                            validRequest = _validateRequest();
                            if (_blockAddressController.text.startsWith("@") &&
                                validRequest) {
                              // Need to make sure its a valid contact
                              sl
                                  .get<DBHelper>()
                                  .getContactWithName(
                                      _blockAddressController.text)
                                  .then((contact) {
                                if (contact == null) {
                                  setState(() {
                                    _addressValidationText =
                                        AppLocalization.of(context)
                                            .contactInvalid;
                                  });
                                } else {
                                  AppDialogs.showConfirmDialog(
                                      context,
                                      AppLocalization.of(context)
                                          .scPushConfirmationTitle,
                                      AppLocalization.of(context)
                                          .scPushConfirmationText,
                                      CaseChange.toUpperCase(
                                          AppLocalization.of(context).yesButton,
                                          context), () async {
                                    ContractCallResponse contractCallResponse =
                                        await sl
                                            .get<SmartContractService>()
                                            .contractCallPushMultiSig(
                                                widget.smartContractMultiSig
                                                    .owner,
                                                widget.smartContractMultiSig
                                                    .contractAddress,
                                                0.25,
                                                contact.address,
                                                widget.smartContractMultiSig
                                                    .balance
                                                    .toString());
                                    if (contractCallResponse != null &&
                                        contractCallResponse.error != null) {
                                      UIUtil.showSnackbar(
                                          AppLocalization.of(context)
                                                  .sendError +
                                              " (" +
                                              contractCallResponse
                                                  .error.message +
                                              ")",
                                          context);
                                      return;
                                    } else {
                                      Navigator.of(context).popUntil(
                                          RouteUtils.withNameLike('/home'));
                                    }
                                  });
                                }
                              });
                            } else if (validRequest) {
                              AppButton.buildAppButton(
                                  context,
                                  AppButtonType.PRIMARY,
                                  AppLocalization.of(context).scPushButton,
                                  Dimens.BUTTON_BOTTOM_SMALL_PLACE,
                                  onPressed: () {
                                AppDialogs.showConfirmDialog(
                                    context,
                                    AppLocalization.of(context)
                                        .scPushConfirmationTitle,
                                    AppLocalization.of(context)
                                        .scPushConfirmationText,
                                    CaseChange.toUpperCase(
                                        AppLocalization.of(context).yesButton,
                                        context), () async {
                                  ContractCallResponse contractCallResponse =
                                      await sl
                                          .get<SmartContractService>()
                                          .contractCallPushMultiSig(
                                              widget
                                                  .smartContractMultiSig.owner,
                                              widget.smartContractMultiSig
                                                  .contractAddress,
                                              0.25,
                                              _blockAddressController.text,
                                              widget
                                                  .smartContractMultiSig.balance
                                                  .toString());
                                  if (contractCallResponse != null &&
                                      contractCallResponse.error != null) {
                                    UIUtil.showSnackbar(
                                        AppLocalization.of(context).sendError +
                                            " (" +
                                            contractCallResponse.error.message +
                                            ")",
                                        context);
                                    return;
                                  } else {
                                    Navigator.of(context).popUntil(
                                        RouteUtils.withNameLike('/home'));
                                  }
                                });
                              });
                            }
                          })
                        : SizedBox(),

                    // SEND COIN
                    _processIndex >= 3
                        ? SizedBox()
                        : AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context).send,
                            Dimens.BUTTON_BOTTOM_SMALL_PLACE, onPressed: () {
                            Sheets.showAppHeightNineSheet(
                                context: context,
                                widget: SendSheet(
                                    address: widget
                                        .smartContractMultiSig.contractAddress,
                                    localCurrency: StateContainer.of(context)
                                        .curCurrency));
                          }),

                    // ADD VOTER BUTTON
                    _processIndex == 1 &&
                            widget.smartContractMultiSig.owner.toUpperCase() ==
                                widget.address.toUpperCase()
                        ? AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context).scAddVoterButton,
                            Dimens.BUTTON_BOTTOM_SMALL_PLACE, onPressed: () {
                            validRequest = _validateRequest();
                            if (_blockAddressController.text.startsWith("@") &&
                                validRequest) {
                              // Need to make sure its a valid contact
                              sl
                                  .get<DBHelper>()
                                  .getContactWithName(
                                      _blockAddressController.text)
                                  .then((contact) {
                                if (contact == null) {
                                  setState(() {
                                    _addressValidationText =
                                        AppLocalization.of(context)
                                            .contactInvalid;
                                  });
                                } else {
                                  AppDialogs.showConfirmDialog(
                                      context,
                                      AppLocalization.of(context)
                                          .scAddVoterConfirmationTitle,
                                      AppLocalization.of(context)
                                          .scAddVoterConfirmationText,
                                      CaseChange.toUpperCase(
                                          AppLocalization.of(context).yesButton,
                                          context), () async {
                                    String privateKey;
                                    String seedOrigin = await sl
                                        .get<SharedPrefsUtil>()
                                        .getSeedOrigin();
                                    String seed =
                                        await StateContainer.of(context)
                                            .getSeed();
                                    if (seedOrigin == HD_WALLET) {
                                      if (seed != null) {
                                        int index = StateContainer.of(context)
                                            .selectedAccount
                                            .index;
                                        privateKey = await AppUtil()
                                            .seedToPrivateKey(seed, index);
                                        //print("privateKey : " + privateKey);
                                      }
                                    }
                                    ContractCallResponse contractCallResponse =
                                        await sl
                                            .get<SmartContractService>()
                                            .contractCallAddMultiSig(
                                                widget.smartContractMultiSig
                                                    .owner,
                                                widget.smartContractMultiSig
                                                    .contractAddress,
                                                0.25,
                                                contact.address,
                                                privateKey == null
                                                    ? seed
                                                    : privateKey);

                                    if (contractCallResponse != null &&
                                        contractCallResponse.error != null) {
                                      UIUtil.showSnackbar(
                                          AppLocalization.of(context)
                                                  .sendError +
                                              " (" +
                                              contractCallResponse
                                                  .error.message +
                                              ")",
                                          context);
                                      return;
                                    } else {
                                      Navigator.of(context).popUntil(
                                          RouteUtils.withNameLike('/home'));
                                    }
                                  });
                                }
                              });
                            } else if (validRequest) {
                              AppDialogs.showConfirmDialog(
                                  context,
                                  AppLocalization.of(context)
                                      .scAddVoterConfirmationTitle,
                                  AppLocalization.of(context)
                                      .scAddVoterConfirmationText,
                                  CaseChange.toUpperCase(
                                      AppLocalization.of(context).yesButton,
                                      context), () async {
                                String privateKey;
                                String seedOrigin = await sl
                                    .get<SharedPrefsUtil>()
                                    .getSeedOrigin();
                                String seed =
                                    await StateContainer.of(context).getSeed();
                                if (seedOrigin == HD_WALLET) {
                                  if (seed != null) {
                                    int index = StateContainer.of(context)
                                        .selectedAccount
                                        .index;
                                    privateKey = await AppUtil()
                                        .seedToPrivateKey(seed, index);
                                    //print("privateKey : " + privateKey);
                                  }
                                }
                                ContractCallResponse contractCallResponse =
                                    await sl
                                        .get<SmartContractService>()
                                        .contractCallAddMultiSig(
                                            widget.smartContractMultiSig.owner,
                                            widget.smartContractMultiSig
                                                .contractAddress,
                                            0.25,
                                            _blockAddressController.text,
                                            privateKey == null
                                                ? seed
                                                : privateKey);

                                if (contractCallResponse != null &&
                                    contractCallResponse.error != null) {
                                  UIUtil.showSnackbar(
                                      AppLocalization.of(context).sendError +
                                          " (" +
                                          contractCallResponse.error.message +
                                          ")",
                                      context);
                                  return;
                                } else {
                                  Navigator.of(context).popUntil(
                                      RouteUtils.withNameLike('/home'));
                                }
                              });
                            }
                          })
                        : SizedBox(),

                    // VOTE (SEND) BUTTON
                    _processIndex > 3
                        ? SizedBox()
                        : AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context).scVoteButton,
                            Dimens.BUTTON_BOTTOM_SMALL_PLACE, onPressed: () {
                            validRequest = _validateRequest();
                            if (_blockAddressController.text.startsWith("@") &&
                                validRequest) {
                              // Need to make sure its a valid contact
                              sl
                                  .get<DBHelper>()
                                  .getContactWithName(
                                      _blockAddressController.text)
                                  .then((contact) {
                                if (contact == null) {
                                  setState(() {
                                    _addressValidationText =
                                        AppLocalization.of(context)
                                            .contactInvalid;
                                  });
                                } else {
                                  AppDialogs.showConfirmDialog(
                                      context,
                                      AppLocalization.of(context)
                                          .scVoteConfirmationTitle,
                                      AppLocalization.of(context)
                                          .scVoteConfirmationText,
                                      CaseChange.toUpperCase(
                                          AppLocalization.of(context).yesButton,
                                          context), () async {
                                    ContractCallResponse contractCallResponse =
                                        await sl
                                            .get<SmartContractService>()
                                            .contractCallSendMultiSig(
                                                widget.smartContractMultiSig
                                                    .owner,
                                                widget.smartContractMultiSig
                                                    .contractAddress,
                                                0.25,
                                                contact.address,
                                                widget.smartContractMultiSig
                                                    .balance
                                                    .toString());
                                    if (contractCallResponse != null &&
                                        contractCallResponse.error != null) {
                                      UIUtil.showSnackbar(
                                          AppLocalization.of(context)
                                                  .sendError +
                                              " (" +
                                              contractCallResponse
                                                  .error.message +
                                              ")",
                                          context);
                                      return;
                                    } else {
                                      Navigator.of(context).popUntil(
                                          RouteUtils.withNameLike('/home'));
                                    }
                                  });
                                }
                              });
                            } else if (validRequest) {
                              AppButton.buildAppButton(
                                  context,
                                  AppButtonType.PRIMARY,
                                  AppLocalization.of(context).scVoteButton,
                                  Dimens.BUTTON_BOTTOM_SMALL_PLACE,
                                  onPressed: () {
                                AppDialogs.showConfirmDialog(
                                    context,
                                    AppLocalization.of(context)
                                        .scVoteConfirmationTitle,
                                    AppLocalization.of(context)
                                        .scVoteConfirmationText,
                                    CaseChange.toUpperCase(
                                        AppLocalization.of(context).yesButton,
                                        context), () async {
                                  await sl
                                      .get<SmartContractService>()
                                      .contractCallSendMultiSig(
                                          widget.smartContractMultiSig.owner,
                                          widget.smartContractMultiSig
                                              .contractAddress,
                                          0.25,
                                          _blockAddressController.text,
                                          widget.smartContractMultiSig.balance
                                              .toString());
                                  Navigator.of(context).popUntil(
                                      RouteUtils.withNameLike('/home'));
                                });
                              });
                            }
                          }),

                    // TERMINATE BUTTON
                    _processIndex == 4
                        ? SizedBox()
                        : AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context).scTerminateButton,
                            Dimens.BUTTON_BOTTOM_SMALL_PLACE, onPressed: () {
                            validRequest = _validateRequest();
                            if (_blockAddressController.text.startsWith("@") &&
                                validRequest) {
                              // Need to make sure its a valid contact
                              sl
                                  .get<DBHelper>()
                                  .getContactWithName(
                                      _blockAddressController.text)
                                  .then((contact) {
                                if (contact == null) {
                                  setState(() {
                                    _addressValidationText =
                                        AppLocalization.of(context)
                                            .contactInvalid;
                                  });
                                } else {
                                  AppDialogs.showConfirmDialog(
                                      context,
                                      AppLocalization.of(context)
                                          .scTerminateConfirmationTitle,
                                      AppLocalization.of(context)
                                          .scTerminateConfirmationText,
                                      CaseChange.toUpperCase(
                                          AppLocalization.of(context).yesButton,
                                          context), () async {
                                    await sl
                                        .get<SmartContractService>()
                                        .contractTerminateMultiSig(
                                            widget.smartContractMultiSig.owner,
                                            widget.smartContractMultiSig
                                                .contractAddress,
                                            0.25,
                                            contact.address);
                                    Navigator.of(context).popUntil(
                                        RouteUtils.withNameLike('/home'));
                                  });
                                }
                              });
                            } else if (validRequest) {
                              AppButton.buildAppButton(
                                  context,
                                  AppButtonType.PRIMARY,
                                  AppLocalization.of(context).scTerminateButton,
                                  Dimens.BUTTON_BOTTOM_SMALL_PLACE,
                                  onPressed: () {
                                AppDialogs.showConfirmDialog(
                                    context,
                                    AppLocalization.of(context)
                                        .scTerminateConfirmationTitle,
                                    AppLocalization.of(context)
                                        .scTerminateConfirmationText,
                                    CaseChange.toUpperCase(
                                        AppLocalization.of(context).yesButton,
                                        context), () async {
                                  await sl
                                      .get<SmartContractService>()
                                      .contractTerminateMultiSig(
                                          widget.smartContractMultiSig.owner,
                                          widget.smartContractMultiSig
                                              .contractAddress,
                                          0.25,
                                          _blockAddressController.text);
                                  Navigator.of(context).popUntil(
                                      RouteUtils.withNameLike('/home'));
                                });
                              });
                            }
                          }),
                  ],
                ),
              ],
            ),
          ],
        ));
  }

  // Build contact items for the list
  Widget _buildContactItem(Contact contact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 42,
          width: double.infinity - 5,
          child: FlatButton(
            onPressed: () {
              _blockAddressController.text = contact.name;
              _blockAddressFocusNode.unfocus();
              setState(() {
                _isContact = true;
                _showContactButton = false;
                _pasteButtonVisible = false;
                _blockAddressStyle = AddressStyle.PRIMARY;
              });
            },
            child: Text(contact.name,
                textAlign: TextAlign.center,
                style: AppStyles.textStyleAddressText90(context)),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 25),
          height: 1,
          color: StateContainer.of(context).curTheme.text03,
        ),
      ],
    );
  }

  /// Validate form data to see if valid
  /// @returns true if valid, false otherwise
  bool _validateRequest() {
    bool isValid = true;
    _blockAddressFocusNode.unfocus();

    // Validate address
    bool isContact = _blockAddressController.text.startsWith("@");
    if (_blockAddressController.text.trim().isEmpty) {
      isValid = false;
      setState(() {
        _addressValidationText = AppLocalization.of(context).addressMising;
        _pasteButtonVisible = true;
      });
    } else if (!isContact && !Address(_blockAddressController.text).isValid()) {
      isValid = false;
      setState(() {
        _addressValidationText = AppLocalization.of(context).invalidAddress;
        _pasteButtonVisible = true;
      });
    } else if (!isContact) {
      setState(() {
        _addressValidationText = "";
        _pasteButtonVisible = false;
      });
      _blockAddressFocusNode.unfocus();
    }

    return isValid;
  }

  getEnterAddressContainer() {
    return AppTextField(
        padding: _addressValidAndUnfocused
            ? EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0)
            : EdgeInsets.zero,
        textAlign: _isContact && false ? TextAlign.start : TextAlign.center,
        focusNode: _blockAddressFocusNode,
        controller: _blockAddressController,
        cursorColor: StateContainer.of(context).curTheme.primary,
        inputFormatters: [
          _isContact
              ? LengthLimitingTextInputFormatter(20)
              : LengthLimitingTextInputFormatter(65),
        ],
        textInputAction: TextInputAction.done,
        maxLines: null,
        autocorrect: false,
        hintText: _addressHint == null
            ? ""
            : AppLocalization.of(context).enterAddress,
        prefixButton: TextFieldButton(
          icon: AppIcons.at,
          onPressed: () {
            if (_showContactButton && _contacts.length == 0) {
              // Show menu
              FocusScope.of(context).requestFocus(_blockAddressFocusNode);
              if (_blockAddressController.text.length == 0) {
                _blockAddressController.text = "@";
                _blockAddressController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _blockAddressController.text.length));
              }
              sl.get<DBHelper>().getContacts().then((contactList) {
                setState(() {
                  _contacts = contactList;
                });
              });
            }
          },
        ),
        fadePrefixOnCondition: true,
        prefixShowFirstCondition: _showContactButton && _contacts.length == 0,
        suffixButton: TextFieldButton(
          icon: AppIcons.paste,
          onPressed: () {
            if (!_pasteButtonVisible) {
              return;
            }
            Clipboard.getData("text/plain").then((ClipboardData data) {
              if (data == null || data.text == null) {
                return;
              }
              Address address = Address(data.text);
              if (address.isValid()) {
                sl
                    .get<DBHelper>()
                    .getContactWithAddress(address.address)
                    .then((contact) {
                  if (contact == null) {
                    setState(() {
                      _isContact = false;
                      _addressValidationText = "";
                      _blockAddressStyle = AddressStyle.TEXT90;
                      _pasteButtonVisible = false;
                      _showContactButton = false;
                    });
                    _blockAddressController.text = address.address;
                    //_blockAddressFocusNode.unfocus();
                    setState(() {
                      //_addressValidAndUnfocused = true;
                    });
                  } else {
                    // Is a contact
                    setState(() {
                      _isContact = true;
                      _addressValidationText = "";
                      _blockAddressStyle = AddressStyle.PRIMARY;
                      _pasteButtonVisible = false;
                      _showContactButton = false;
                    });
                    _blockAddressController.text = contact.name;
                  }
                });
              }
            });
          },
        ),
        fadeSuffixOnCondition: true,
        suffixShowFirstCondition: _pasteButtonVisible,
        style: _blockAddressStyle == AddressStyle.TEXT60
            ? AppStyles.textStyleAddressText60(context)
            : _blockAddressStyle == AddressStyle.TEXT90
                ? AppStyles.textStyleAddressText90(context)
                : AppStyles.textStyleAddressText90(context),
        onChanged: (text) {
          if (text.length > 0) {
            setState(() {
              _showContactButton = false;
            });
          } else {
            setState(() {
              _showContactButton = true;
            });
          }
          bool isContact = text.startsWith("@");
          // Switch to contact mode if starts with @
          if (isContact) {
            setState(() {
              _isContact = true;
            });
            sl
                .get<DBHelper>()
                .getContactsWithNameLike(text)
                .then((matchedList) {
              setState(() {
                _contacts = matchedList;
              });
            });
          } else {
            setState(() {
              _isContact = false;
              _contacts = [];
            });
          }
          // Always reset the error message to be less annoying
          setState(() {
            _addressValidationText = "";
          });
          if (!isContact && Address(text).isValid()) {
            //_blockAddressFocusNode.unfocus();
            setState(() {
              _blockAddressStyle = AddressStyle.TEXT90;
              _addressValidationText = "";
              _pasteButtonVisible = true;
            });
          } else if (!isContact) {
            setState(() {
              _blockAddressStyle = AddressStyle.TEXT60;
              _pasteButtonVisible = true;
            });
          } else {
            sl.get<DBHelper>().getContactWithName(text).then((contact) {
              if (contact == null) {
                setState(() {
                  _blockAddressStyle = AddressStyle.TEXT60;
                });
              } else {
                setState(() {
                  _pasteButtonVisible = false;
                  _addressValidationText = "";
                  _blockAddressStyle = AddressStyle.PRIMARY;
                });
              }
            });
          }
        },
        overrideTextFieldWidget: _addressValidAndUnfocused
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _addressValidAndUnfocused = false;
                    _addressValidationText = "";
                  });
                  Future.delayed(Duration(milliseconds: 50), () {
                    FocusScope.of(context).requestFocus(_blockAddressFocusNode);
                  });
                },
                child: UIUtil.threeLineAddressText(
                    context, _blockAddressController.text))
            : null);
  }
}

class _BezierPainter extends CustomPainter {
  const _BezierPainter({
    @required this.color,
    this.drawStart = true,
    this.drawEnd = true,
  });

  final Color color;
  final bool drawStart;
  final bool drawEnd;

  Offset _offset(double radius, double angle) {
    return Offset(
      radius * cos(angle) + radius,
      radius * sin(angle) + radius,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final radius = size.width / 2;

    var angle;
    var offset1;
    var offset2;

    var path;

    if (drawStart) {
      angle = 3 * pi / 4;
      offset1 = _offset(radius, angle);
      offset2 = _offset(radius, -angle);
      path = Path()
        ..moveTo(offset1.dx, offset1.dy)
        ..quadraticBezierTo(0.0, size.height / 2, -radius, radius)
        ..quadraticBezierTo(0.0, size.height / 2, offset2.dx, offset2.dy)
        ..close();

      canvas.drawPath(path, paint);
    }
    if (drawEnd) {
      angle = -pi / 4;
      offset1 = _offset(radius, angle);
      offset2 = _offset(radius, -angle);

      path = Path()
        ..moveTo(offset1.dx, offset1.dy)
        ..quadraticBezierTo(
            size.width, size.height / 2, size.width + radius, radius)
        ..quadraticBezierTo(size.width, size.height / 2, offset2.dx, offset2.dy)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BezierPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.drawStart != drawStart ||
        oldDelegate.drawEnd != drawEnd;
  }
}
