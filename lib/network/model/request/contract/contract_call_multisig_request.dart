// To parse this JSON data, do
//
//     final contractCallMultiSigRequest = contractCallMultiSigRequestFromJson(jsonString);

import 'dart:convert';

ContractCallMultiSigRequest contractCallMultiSigRequestFromJson(String str) => ContractCallMultiSigRequest.fromJson(json.decode(str));

String contractCallMultiSigRequestToJson(ContractCallMultiSigRequest data) => json.encode(data.toJson());

class ContractCallMultiSigRequest {
    ContractCallMultiSigRequest({
        this.method,
        this.params,
        this.id,
        this.key,
    });

    String method;
    List<Param> params;
    int id;
    String key;

    static const METHOD_NAME = "contract_call";

    factory ContractCallMultiSigRequest.fromJson(Map<String, dynamic> json) => ContractCallMultiSigRequest(
        method: json["method"],
        params: List<Param>.from(json["params"].map((x) => Param.fromJson(x))),
        id: json["id"],
        key: json["key"],
    );

    Map<String, dynamic> toJson() => {
        "method": method,
        "params": List<dynamic>.from(params.map((x) => x.toJson())),
        "id": id,
        "key": key,
    };
}

class Param {
    Param({
        this.from,
        this.contract,
        this.method,
        this.maxFee,
        this.args,
    });

    String from;
    String contract;
    String method;
    double amount;
    List<Arg> args;
    double maxFee;
    int broadcastBlock;

    factory Param.fromJson(Map<String, dynamic> json) => Param(
        from: json["from"],
        contract: json["contract"],
        method: json["method"],
        maxFee: json["maxFee"],
        args: List<Arg>.from(json["args"].map((x) => Arg.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "from": from,
        "contract": contract,
        "method": method,
        "maxFee": maxFee,
        "args": List<dynamic>.from(args.map((x) => x.toJson())),
    };
}

class Arg {
    Arg({
        this.index,
        this.format,
        this.value,
    });

    int index;
    String format;
    String value;

    factory Arg.fromJson(Map<String, dynamic> json) => Arg(
        index: json["index"],
        format: json["format"],
        value: json["value"],
    );

    Map<String, dynamic> toJson() => {
        "index": index,
        "format": format,
        "value": value,
    };
}
