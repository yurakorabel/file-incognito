# Create an SNS Topic
resource "aws_sns_topic" "file_access_notifications" {
  name = "FileAccessNotifications" # Name of the SNS topic
}

# Create SNS Topic Subscriptions for Each Email Recipient
resource "aws_sns_topic_subscription" "email_subscriptions" {
  for_each  = toset(var.email_recipients) # Iterate over each unique email in the list
  topic_arn = aws_sns_topic.file_access_notifications.arn
  protocol  = "email"
  endpoint  = each.value # Each subscription's endpoint is the email address
}
