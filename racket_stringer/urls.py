from django.urls import path, reverse_lazy
from django.views.generic.base import RedirectView

from . import views

urlpatterns = [
    path(
        "",
        RedirectView.as_view(url=reverse_lazy("new_order")),
        name="index",
    ),
    path("orders", views.Orders.as_view(), name="orders"),
    path("new_order", views.NewOrder.as_view(), name="new_order"),
    path(
        "show_order/<int:pk>",
        views.ShowOrder.as_view(),
        name="show_order",
    ),
    path(
        "update_order/<int:pk>",
        views.UpdateOrder.as_view(),
        name="update_order",
    ),
    path(
        "delete_order/<int:pk>",
        views.DeleteOrder.as_view(),
        name="delete_order",
    ),
    path(
        "new_customer", views.NewCustomer.as_view(), name="new_customer"
    ),
    path("new_string", views.NewString.as_view(), name="new_string"),
    path("search_rackets", views.search_rackets, name="search_rackets"),
    path("search_strings", views.search_strings, name="search_strings"),
]
