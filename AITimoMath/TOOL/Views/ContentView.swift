import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = QuestionParserViewModel()
    @State private var isFilePickerPresented = false
    @State private var isSaveDialogPresented = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                Text("TIMO Question Parser")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Convert text files to timo_questions.json format")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Status and error messages
                StatusView(viewModel: viewModel)
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // File selection section
                        FileSelectionView(
                            viewModel: viewModel,
                            isFilePickerPresented: $isFilePickerPresented
                        )
                        
                        // Parsed questions section
                        if !viewModel.parsedQuestions.isEmpty {
                            ParsedQuestionsView(viewModel: viewModel)
                        }
                        
                        // JSON preview section
                        if !viewModel.jsonContent.isEmpty {
                            JsonPreviewView(viewModel: viewModel)
                        }
                    }
                    .padding()
                }
                
                // Action buttons
                ActionButtonsView(
                    viewModel: viewModel,
                    isSaveDialogPresented: $isSaveDialogPresented
                )
            }
            .padding()
            .navigationTitle("TIMO Question Parser")
            .sheet(isPresented: $isFilePickerPresented) {
                DocumentPicker(viewModel: viewModel)
            }
            .fileExporter(
                isPresented: $isSaveDialogPresented,
                document: JsonDocument(jsonContent: viewModel.jsonContent),
                contentType: .json,
                defaultFilename: "timo_questions.json"
            ) { result in
                switch result {
                case .success(let url):
                    viewModel.statusMessage = "JSON saved successfully to \(url.lastPathComponent)."
                    viewModel.isSuccess = true
                case .failure(let error):
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.statusMessage = "Failed to save JSON."
                }
            }
        }
    }
}

// MARK: - Status View
struct StatusView: View {
    @ObservedObject var viewModel: QuestionParserViewModel
    
    var body: some View {
        VStack {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text(viewModel.statusMessage)
                .foregroundColor(viewModel.isSuccess ? .green : .primary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
        .padding(.vertical)
    }
}

// MARK: - File Selection View
struct FileSelectionView: View {
    @ObservedObject var viewModel: QuestionParserViewModel
    @Binding var isFilePickerPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("1. Select Text File")
                .font(.headline)
            
            HStack {
                Button(action: {
                    isFilePickerPresented = true
                }) {
                    Label("Select File", systemImage: "doc")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                if let url = viewModel.selectedFileURL {
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.leading)
                }
            }
            
            if !viewModel.fileContent.isEmpty {
                Text("File Content Preview:")
                    .font(.subheadline)
                    .padding(.top)
                
                ScrollView {
                    Text(viewModel.fileContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(height: 200)
            }
        }
    }
}

// MARK: - Parsed Questions View
struct ParsedQuestionsView: View {
    @ObservedObject var viewModel: QuestionParserViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("2. Parsed Questions")
                .font(.headline)
            
            Text("Found \(viewModel.parsedQuestions.count) questions:")
                .font(.subheadline)
                .padding(.bottom, 5)
            
            List {
                ForEach(viewModel.parsedQuestions, id: \.id) { question in
                    VStack(alignment: .leading) {
                        Text("Subject: \(question.subject)")
                            .font(.headline)
                        
                        Text("Question \(question.questionNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(question.content)
                            .padding(.vertical, 5)
                        
                        if !question.options.isEmpty {
                            Text("Options:")
                                .font(.subheadline)
                            
                            ForEach(question.options.indices, id: \.self) { index in
                                Text("\(["A", "B", "C", "D"][min(index, 3)]). \(question.options[index])")
                                    .padding(.leading)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .frame(height: 300)
            .cornerRadius(8)
        }
    }
}

// MARK: - JSON Preview View
struct JsonPreviewView: View {
    @ObservedObject var viewModel: QuestionParserViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("3. Generated JSON")
                .font(.headline)
            
            ScrollView {
                Text(viewModel.jsonContent)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(height: 200)
        }
    }
}

// MARK: - Action Buttons View
struct ActionButtonsView: View {
    @ObservedObject var viewModel: QuestionParserViewModel
    @Binding var isSaveDialogPresented: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.reset()
            }) {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.saveJson()
            }) {
                Label("Save to App", systemImage: "square.and.arrow.down")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.jsonContent.isEmpty)
            
            Button(action: {
                isSaveDialogPresented = true
            }) {
                Label("Export JSON", systemImage: "arrow.down.doc")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.jsonContent.isEmpty)
        }
        .padding()
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    @ObservedObject var viewModel: QuestionParserViewModel
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.text, .plainText])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let viewModel: QuestionParserViewModel
        
        init(viewModel: QuestionParserViewModel) {
            self.viewModel = viewModel
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            viewModel.selectFile(url: url)
        }
    }
}

// MARK: - JSON Document
struct JsonDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var jsonContent: String
    
    init(jsonContent: String) {
        self.jsonContent = jsonContent
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.jsonContent = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = jsonContent.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
} 