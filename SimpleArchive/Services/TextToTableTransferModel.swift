import FoundationModels

@available(iOS 26.0, *)
@Generable
struct TableData {
    @Guide(description: "List of names of columns")
    var columns: [String]

    var rows: [GenRow]
}

@available(iOS 26.0, *)
@Generable
struct GenRow {
    @Guide(description: "It is a list of data in one column and the length must be equal to the length of columns.")
    var datas: [String]
}

final class TextToTableTransferModel {
    @available(iOS 26.0, *)
    static func dd() {
        Task {
            let session = LanguageModelSession(instructions: directGenTablePrompt)
            do {
                let res = try await session.respond(to: test_1, generating: TableData.self)
                for i in 0..<res.content.columns.count {
                    print(res.content.columns[i])
                    for cell in res.content.rows {
						myLog("\(cell.datas[i])")
                    }
                }
            } catch {
                print("error: \(error.localizedDescription)")
            }
        }
    }
	
	private static let directGenTablePrompt =
		"""
		I'm gonna give you some memo data.
		Your mission is to extract data from the memo and make it the most natural and appropriate table format
		Table format means rows and columns and data for each cell
		First, Find out what the string means
		you need to figure out the number of rows and columns, 
		and find the name of the column in the problem column
		If a partial string is determined to be the cell's data,
		the cell's data should never be changed and entered in the table as it is
		Similarly, if a partial string is determined to be the name of a column, it should never be changed
		If you can't find any cell data in the string, you need to put an empty string
		"""

	private static let test_1 =
		"""
		This is a memo that I wrote down the weather, wake-up time, rush hour, and consumption details
		There are five columns, dates, weather, work, weather, and consumption details

		Date: 3/1 (Fri)
		Wake up: 08:00
		Go to work: 09:15
		Weather: Clear

		Lunch 12:30 Gukbap
		Price 8000 KRW
		Payment Card
		Note Near the office

		Around 4 PM coffee
		Americano
		4500 KRW
		Crowded

		Leave work 18:05
		Arrive home 19:30


		Date: 3/2 (Sat)
		Wake up 10:30
		No outing
		Weather Good

		Lunch ramen at home
		Price 1500 KRW
		Added egg

		Afternoon walk 40 minutes
		Stopped by a café
		Latte
		5200
		Cash

		Dinner fried chicken delivery
		18000
		Card
		Left half


		Date 3/3 Sun
		Wake up 11:00
		Weather Rainy

		Skipped lunch

		Afternoon met a friend
		Place Café
		Coffee iced Americano
		Price 4800
		Friend paid

		Dinner pasta
		14500
		Card
		Portion was decent                       
		"""
}
