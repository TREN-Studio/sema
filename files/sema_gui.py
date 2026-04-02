import sys
import os
import threading
import traceback
from pathlib import Path

try:
    import customtkinter as ctk
    from tkinter import filedialog, messagebox
except ImportError:
    print("Please install required packages: pip install customtkinter")
    sys.exit(1)

# Import the builder engine
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
try:
    import sema_builder
except ImportError as e:
    print(f"Error loading sema_builder.py: {e}")
    sys.exit(1)

# UI Theme Setup
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("green")

class SemaGuiBuilder(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("SEMA Builder — TREN Studio")
        self.geometry("600x480")
        self.resizable(False, False)
        
        # Center the window
        self.eval('tk::PlaceWindow . center')

        # Colors (TREN Studio theme)
        self.bg_color = "#0d1117"
        self.surface_color = "#161b22"
        self.accent_color = "#00ff88"
        self.text_color = "#e6edf3"
        
        self.configure(fg_color=self.bg_color)

        # Header Title
        self.title_label = ctk.CTkLabel(
            self, 
            text="SEMA Builder", 
            font=ctk.CTkFont(family="Arial", size=32, weight="bold"),
            text_color=self.accent_color
        )
        self.title_label.pack(pady=(40, 5))

        self.subtitle_label = ctk.CTkLabel(
            self, 
            text="The File That Knows Itself.", 
            font=ctk.CTkFont(size=14),
            text_color="#8b949e"
        )
        self.subtitle_label.pack(pady=(0, 30))

        # File Selection Frame
        self.frame = ctk.CTkFrame(self, fg_color=self.surface_color, corner_radius=15)
        self.frame.pack(pady=10, padx=40, fill="both", expand=True)

        self.status_label = ctk.CTkLabel(
            self.frame, 
            text="Select a document, image, or text file\nto convert it into a semantic archive.", 
            font=ctk.CTkFont(size=14),
            text_color=self.text_color
        )
        self.status_label.pack(pady=(40, 20))

        # Select Button
        self.select_btn = ctk.CTkButton(
            self.frame, 
            text="Choose File", 
            command=self.select_file,
            width=200,
            height=45,
            font=ctk.CTkFont(size=16, weight="bold"),
            fg_color=self.accent_color,
            text_color="#000000",
            hover_color="#00cc6a"
        )
        self.select_btn.pack(pady=20)

        # Progress Bar
        self.progress = ctk.CTkProgressBar(self.frame, width=400, progress_color=self.accent_color)
        self.progress.pack(pady=10)
        self.progress.set(0)
        self.progress.pack_forget() # Hide initially

        # Footer
        self.footer_label = ctk.CTkLabel(
            self, 
            text="TREN Studio © 2026", 
            font=ctk.CTkFont(size=12),
            text_color="#484f58"
        )
        self.footer_label.pack(side="bottom", pady=15)

    def select_file(self):
        file_path = filedialog.askopenfilename(
            title="Select File to Convert",
            filetypes=[
                ("All Supported Files", "*.pdf *.docx *.txt *.xlsx *.csv *.jpg *.png *.webp"),
                ("Documents", "*.pdf *.docx *.txt *.xlsx *.csv"),
                ("Images", "*.jpg *.jpeg *.png *.webp"),
                ("All Files", "*.*")
            ]
        )

        if file_path:
            self.start_build_thread(file_path)

    def start_build_thread(self, file_path):
        filename = os.path.basename(file_path)
        self.status_label.configure(text=f"Analyzing and Building...\n{filename}")
        self.select_btn.configure(state="disabled", text="Processing...")
        self.progress.pack(pady=10)
        self.progress.start()

        # Run in a background thread to prevent UI freezing
        thread = threading.Thread(target=self.run_builder_task, args=(file_path,))
        thread.daemon = True
        thread.start()

    def run_builder_task(self, file_path):
        try:
            # Let the builder use its NLP magic
            output_path = sema_builder.build_sema(
                input_path=file_path, 
                author_name="TREN Studio User",
                verbose=False
            )
            self.after(100, self.on_build_success, output_path)
            
        except Exception as e:
            err = traceback.format_exc()
            self.after(100, self.on_build_fail, str(e))

    def on_build_success(self, output_path):
        self.progress.stop()
        self.progress.set(1.0)
        self.select_btn.configure(state="normal", text="Convert Another File")
        
        filename = os.path.basename(output_path)
        self.status_label.configure(
            text=f"SUCCESS!\n{filename} has been created.\n\nDouble click it to view!",
            text_color=self.accent_color
        )
        
        # Open the folder containing the generated file (Windows)
        try:
            os.startfile(os.path.dirname(output_path))
        except:
            pass

    def on_build_fail(self, error_message):
        self.progress.stop()
        self.progress.pack_forget()
        self.select_btn.configure(state="normal", text="Choose File")
        self.status_label.configure(
            text=f"ERROR:\n{error_message[:100]}...",
            text_color="#ff6b35"
        )
        messagebox.showerror("Build Failed", f"An error occurred:\n{error_message}")

if __name__ == "__main__":
    app = SemaGuiBuilder()
    app.mainloop()
