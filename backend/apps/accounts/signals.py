from django.db.models.signals import pre_save, post_save
from django.dispatch import receiver
from .models import User, PasswordHistory

@receiver(pre_save, sender=User)
def track_password_change(sender, instance, **kwargs):
    if instance.pk:
        old_instance = sender.objects.filter(pk=instance.pk).first()
        if old_instance and old_instance.password != instance.password:
            # Add old password to history
            PasswordHistory.objects.create(
                user=instance,
                password_hash=old_instance.password
            )
            from django.utils import timezone
            instance.password_changed_at = timezone.now()
