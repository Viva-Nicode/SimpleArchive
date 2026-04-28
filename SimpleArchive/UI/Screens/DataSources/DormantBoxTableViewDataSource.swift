import UIKit

final class DormantBoxTableViewDataSource: NSObject, UITableViewDataSource {
    private var dormantBox: MemoDirectoryModel

    init(dormantBox: MemoDirectoryModel) {
        self.dormantBox = dormantBox
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		dormantBox.items.count
	}

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let storageItem = dormantBox.items[indexPath.row] as! MemoPageModel
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: RemovedItemView.reuseIdentifier,
                for: indexPath) as! RemovedItemView

        cell.configure(item: storageItem)

        return cell
    }
}
