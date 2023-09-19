import 'dart:async';
import 'dart:math';

import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addCategoryPage.dart';
import 'package:budget/pages/addObjectivePage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/globalSnackBar.dart';
import 'package:budget/widgets/noResults.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/selectCategory.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide SliverReorderableList;
import 'package:flutter/services.dart' hide TextInput;
import 'package:budget/widgets/editRowEntry.dart';
import 'package:budget/modified/reorderable_list.dart';

class EditObjectivesPage extends StatefulWidget {
  EditObjectivesPage({
    Key? key,
  }) : super(key: key);

  @override
  _EditObjectivesPageState createState() => _EditObjectivesPageState();
}

class _EditObjectivesPageState extends State<EditObjectivesPage> {
  bool dragDownToDismissEnabled = true;
  int currentReorder = -1;
  String searchValue = "";

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      database.fixOrderCategories();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (searchValue != "") {
          setState(() {
            searchValue = "";
          });
          return false;
        } else {
          return true;
        }
      },
      child: PageFramework(
        horizontalPadding: getHorizontalPaddingConstrained(context),
        dragDownToDismiss: true,
        dragDownToDismissEnabled: dragDownToDismissEnabled,
        title: "goals".tr(),
        scrollToTopButton: true,
        floatingActionButton: AnimateFABDelayed(
          fab: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom),
            child: FAB(
              tooltip: "add-goal".tr(),
              openPage: AddObjectivePage(
                routesToPopAfterDelete: RoutesToPopAfterDelete.None,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.all(15),
            tooltip: "add-goal".tr(),
            onPressed: () {
              pushRoute(
                context,
                AddObjectivePage(
                  routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                ),
              );
            },
            icon: Icon(appStateSettings["outlinedIcons"]
                ? Icons.add_outlined
                : Icons.add_rounded),
          ),
        ],
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextInput(
                labelText: "search-goals-placeholder".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.search_outlined
                    : Icons.search_rounded,
                onSubmitted: (value) {
                  setState(() {
                    searchValue = value;
                  });
                },
                onChanged: (value) {
                  setState(() {
                    searchValue = value;
                  });
                },
                autoFocus: false,
              ),
            ),
          ),
          StreamBuilder<List<Objective>>(
            stream: database.watchAllObjectives(
                searchFor: searchValue == "" ? null : searchValue),
            builder: (context, snapshot) {
              if (snapshot.hasData && (snapshot.data ?? []).length <= 0) {
                return SliverToBoxAdapter(
                  child: NoResults(
                    message: "no-goals-found".tr(),
                  ),
                );
              }
              if (snapshot.hasData && (snapshot.data ?? []).length > 0) {
                return SliverReorderableList(
                  onReorderStart: (index) {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      dragDownToDismissEnabled = false;
                      currentReorder = index;
                    });
                  },
                  onReorderEnd: (_) {
                    setState(() {
                      dragDownToDismissEnabled = true;
                      currentReorder = -1;
                    });
                  },
                  itemBuilder: (context, index) {
                    Objective objective = snapshot.data![index];
                    return EditRowEntry(
                      canReorder: searchValue == "" &&
                          (snapshot.data ?? []).length != 1,
                      currentReorder:
                          currentReorder != -1 && currentReorder != index,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      key: ValueKey(objective.objectivePk),
                      content: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CategoryIcon(
                            categoryPk: "-1",
                            size: 31,
                            category: TransactionCategory(
                              categoryPk: "-1",
                              name: "",
                              dateCreated: DateTime.now(),
                              dateTimeModified: null,
                              order: 0,
                              income: false,
                              iconName: objective.iconName,
                              colour: objective.colour,
                              emojiIconName: objective.emojiIconName,
                            ),
                            canEditByLongPress: false,
                            borderRadius: 1000,
                            sizePadding: 23,
                          ),
                          Container(width: 5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFont(
                                  text: objective.name,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                ),
                                TextFont(
                                  textAlign: TextAlign.left,
                                  text: objective.income
                                      ? "savings-goal".tr()
                                      : "expense-goal".tr(),
                                  fontSize: 14,
                                  textColor: getColor(context, "black")
                                      .withOpacity(0.65),
                                ),
                                StreamBuilder<int?>(
                                  stream: database
                                      .getTotalCountOfTransactionsInObjective(
                                          objective.objectivePk)
                                      .$1,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      return TextFont(
                                        textAlign: TextAlign.left,
                                        text: snapshot.data.toString() +
                                            " " +
                                            (snapshot.data == 1
                                                ? "transaction"
                                                    .tr()
                                                    .toLowerCase()
                                                : "transactions"
                                                    .tr()
                                                    .toLowerCase()),
                                        fontSize: 14,
                                        textColor: getColor(context, "black")
                                            .withOpacity(0.65),
                                      );
                                    } else {
                                      return TextFont(
                                        textAlign: TextAlign.left,
                                        text: "/ transactions",
                                        fontSize: 14,
                                        textColor: getColor(context, "black")
                                            .withOpacity(0.65),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      index: index,
                      onDelete: () async {
                        deleteObjectivePopup(context,
                            objective: objective,
                            routesToPopAfterDelete:
                                RoutesToPopAfterDelete.None);
                        return true;
                      },
                      openPage: AddObjectivePage(
                        objective: objective,
                        routesToPopAfterDelete: RoutesToPopAfterDelete.One,
                      ),
                    );
                  },
                  itemCount: snapshot.data!.length,
                  onReorder: (_intPrevious, _intNew) async {
                    Objective oldObjective = snapshot.data![_intPrevious];
                    if (_intNew > _intPrevious) {
                      await database.moveObjective(oldObjective.objectivePk,
                          _intNew - 1, oldObjective.order);
                    } else {
                      await database.moveObjective(oldObjective.objectivePk,
                          _intNew, oldObjective.order);
                    }
                    return true;
                  },
                );
              }
              return SliverToBoxAdapter(
                child: Container(),
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 75),
          ),
        ],
      ),
    );
  }
}

Future<DeletePopupAction?> deleteObjectivePopup(
  BuildContext context, {
  required Objective objective,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  DeletePopupAction? action = await openDeletePopup(
    context,
    title: "delete-goal-question".tr(),
    subtitle: objective.name,
  );
  if (action == DeletePopupAction.Delete) {
    dynamic result = true;
    int? numTransactions = await database
        .getTotalCountOfTransactionsInObjective(objective.objectivePk)
        .$2;
    if (numTransactions != null && numTransactions > 0) {
      result = await openPopup(
        context,
        title: "remove-transactions-from-goal-question".tr(),
        description: "delete-goal-warning".tr(),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.warning_amber_outlined
            : Icons.warning_amber_rounded,
        onCancel: () {
          Navigator.pop(context, false);
        },
        onCancelLabel: "cancel".tr(),
        onSubmit: () async {
          Navigator.pop(context, true);
        },
        onSubmitLabel: "delete-goal".tr(),
      );
    }
    if (result == true) {
      if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
        Navigator.of(context).pop();
      }
      openLoadingPopupTryCatch(() async {
        await database.deleteObjective(context, objective);
        openSnackbar(
          SnackbarMessage(
            title: "deleted-goal".tr(),
            icon: Icons.delete,
            description: objective.name,
          ),
        );
      });
    }
  }
  return action;
}
