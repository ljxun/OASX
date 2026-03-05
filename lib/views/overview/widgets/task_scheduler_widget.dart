part of overview;

class _SchedulerWidget extends StatelessWidget {
  const _SchedulerWidget({
    required this.controller,
  });

  final OverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(I18n.scheduler.tr,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Obx(() {
              return switch (controller.scriptModel.state.value) {
                ScriptState.running => const SpinKitChasingDots(
                    color: Colors.green,
                    size: 22,
                  ),
                ScriptState.inactive =>
                  const Icon(Icons.donut_large, size: 26, color: Colors.grey),
                ScriptState.warning =>
                  const SpinKitDoubleBounce(color: Colors.orange, size: 26),
                ScriptState.updating => const Icon(
                    Icons.browser_updated_rounded,
                    size: 26,
                    color: Colors.blue),
              };
            }),
            Obx(() {
              return IconButton(
                onPressed: () => {controller.toggleScript()},
                icon: const Icon(Icons.power_settings_new_rounded),
                isSelected:
                    controller.scriptModel.state.value == ScriptState.running,
              );
            }),
          ],
        ),
        const Divider(),
      ],
    );
  }
}
