import 'package:flutter/material.dart';
import 'package:gogas_delivery_app/model/order.dart';

class TotalUserDialog extends StatelessWidget {
  final List<User> users;

  const TotalUserDialog({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        width: 400,
        height: 550,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28)),
                    color: colorScheme.primary),
                height: 60,
                alignment: Alignment.center,
                child: Text(
                  "Totale Ordinanti",
                  style: TextStyle(fontSize: 24, color: Colors.white),
                )),
            Expanded(
              child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            bottom: BorderSide(
                                color: Color.fromARGB(255, 218, 218, 218))),
                      ),
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        title: Text(
                          "${users[index].firstName} ${users[index].lastName}",
                          style: const TextStyle(fontSize: 20),
                        ),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: Colors.white,
                          child: Text("${users[index].position}",
                              style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w100)),
                        ),
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
