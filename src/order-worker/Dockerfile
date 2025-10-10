# Use a slim and secure official Python image (Debian-based)
FROM python:3.11-slim

WORKDIR /app

# Copy requirements first to leverage Docker layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the application code
COPY app.py .

# --- Security: Create a dedicated user and group (DEBIAN SYNTAX) ---
RUN adduser --system --group appuser

# Switch to the newly created non-root user
USER appuser

# Expose the port the app listens on (for documentation and clarity)
EXPOSE 5000

# Define the command to start the app
CMD [ "python", "app.py" ]