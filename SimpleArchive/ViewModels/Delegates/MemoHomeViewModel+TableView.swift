import UIKit

extension MemoHomeViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fixedFileDirectory.getChildItemSize()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let storageItem = fixedFileDirectory[indexPath.row]!
        let cell = tableView.dequeueReusableCell(withIdentifier: MemoTableRowView.cellId, for: indexPath) as! MemoTableRowView

        cell.configure(with: storageItem)
        return cell
    }
}
