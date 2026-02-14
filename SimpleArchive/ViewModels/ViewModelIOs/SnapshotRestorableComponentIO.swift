enum SnapshotRestorableComponentAction {
    case willManualCapturePageComponent(description: String)
    case willNavigateComponentSnapshotView
}

enum SnapshotRestorableComponentEvent {
    case didManualCapturePageComponent
    case didNavigateComponentSnapshotView(ComponentSnapshotViewModel)
}
